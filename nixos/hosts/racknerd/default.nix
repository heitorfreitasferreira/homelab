# VPS RackNerd: 5 vCPU, 6 GB, 100 GB, KVM com BIOS (sem UEFI), IP estatico.
{ pkgs, ... }:
{
  imports = [
    ./disk.nix
    ./hardware.nix
    ./network.nix
    ./containers.nix
    ./postgres.nix
    ./caddy.nix
    ./tailscale-services.nix
    ./nextcloud.nix
    ./securo.nix
    ./waha.nix
    ./pihole.nix
    ./audiobooks.nix
    ./glance.nix
    ./monitoring.nix
    ./agents.nix
    ./backup.nix
  ];

  networking.hostName = "racknerd";

  # O comin usa um checkout proprio e nao reinicia quando a config muda.
  # Este timer mantem o clone de trabalho do Hermes, que e o cwd dele, no main.
  systemd.services.homelab-sync = {
    description = "Atualiza o clone de trabalho do Hermes";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.openssh ];
    serviceConfig = {
      Type = "oneshot";
      User = "htr";
      Group = "htr";
      Environment = "HOME=/home/htr";
      ExecStart = pkgs.writeShellScript "homelab-sync" ''
        ${pkgs.git}/bin/git -C /home/htr/homelab pull --ff-only --quiet \
          || echo "homelab-sync: pull falhou" >&2
      '';
    };
  };
  systemd.timers.homelab-sync = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
    };
  };
}
