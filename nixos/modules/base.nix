# Comum a todos os hosts: usuario, SSH, Tailscale, Nix, comin, sops e metricas do host.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  system.stateVersion = "26.05";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";

  # Root sem senha: entra so pelo console do provedor com o htr e sudo.
  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.groups.htr.gid = 1000;
  users.users.htr = {
    isNormalUser = true;
    uid = 1000;
    group = "htr";
    extraGroups = [
      "wheel"
      "systemd-journal"
    ];
    # Sem senha valida, mas conta ativa. "!" marcaria a conta como bloqueada,
    # e o sshd recusaria ate a chave (achado no ensaio).
    hashedPassword = "*";
    linger = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQOe/8Byvgfm8cMhzfplDufCqonIz57NGip3i835ugu heitor.ff@hotmail.com"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # O estado em /var/lib/tailscale vem do backup: o no continua sendo o mesmo da tailnet.
  # DNS do host fica nos resolvedores publicos: o Pi-hole roda aqui e nao pode ser pre-requisito.
  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraSetFlags = [ "--accept-dns=false" ];
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };

  # So os nomes da tailnet vao ao MagicDNS. O resto usa os resolvedores globais do host.
  # O tailscaled (com --accept-dns=false) limpa o DNS do link quando reconfigura:
  # um timer reaplica a cada 30 s.
  services.resolved.enable = true;
  systemd.services.tailscale-dns-route = {
    description = "Rota DNS de tail76c1c6.ts.net para o MagicDNS";
    after = [ "tailscaled.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.iproute2}/bin/ip link show tailscale0 >/dev/null 2>&1 || exit 0
      ${pkgs.systemd}/bin/resolvectl dns tailscale0 100.100.100.100
      ${pkgs.systemd}/bin/resolvectl domain tailscale0 '~tail76c1c6.ts.net'
    '';
  };
  systemd.timers.tailscale-dns-route = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "20s";
      OnUnitActiveSec = "30s";
    };
  };

  # Binarios prontos (Hermes, OpenCode, Anytype) esperam um /lib64/ld-linux.
  programs.nix-ld.enable = true;

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';

  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    jq
    rsync
    sqlite
    tmux
    vim
  ];

  # Metricas do host. A porta 9100 so fica aberta na tailnet (interface confiavel).
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "systemd"
      "textfile"
    ];
    extraFlags = [ "--collector.textfile.directory=/var/lib/prometheus/node-exporter" ];
  };
  systemd.tmpfiles.rules = [ "d /var/lib/prometheus/node-exporter 0755 root root -" ];

  # Chave age copiada na instalacao. Decifra os secrets/<host>.sops.yaml no boot.
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = ../secrets/${config.networking.hostName}.sops.yaml;
  };

  # GitOps: puxa o main a cada minuto e aplica a config deste host.
  services.comin = {
    enable = true;
    repositorySubdir = "nixos";
    remotes = [
      {
        name = "origin";
        url = "https://github.com/heitorfreitasferreira/homelab.git";
        branches.main.name = "main";
      }
    ];
  };
}
