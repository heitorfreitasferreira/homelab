# Agentes do usuario htr: Hermes (gateway do Telegram e dashboard), OpenCode e Anytype.
# Os binarios vivem no home (instaladores proprios de cada um) e rodam pelo nix-ld.
# As unidades replicam as do Debian, com o PATH do NixOS no lugar de /usr/bin.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = "/home/htr";
  hermesBin = "${home}/.hermes/hermes-agent/.hermes/bin/hermes";
  sysPath = "/run/wrappers/bin:/run/current-system/sw/bin";
  hermesPath = lib.concatStringsSep ":" [
    "${home}/.hermes/tools/node-26.12.1-linux-x64/bin"
    "${home}/.hermes/tools/npm-12.2.2-linux-x64/bin"
    "${home}/.hermes/hermes-agent/node_modules/.bin"
    "${home}/.local/bin"
    "/usr/local/sbin"
    sysPath
    "/usr/local/bin"
  ];
  hermesEnv = {
    HOME = home;
    USER = "htr";
    LOGNAME = "htr";
    PATH = lib.mkForce hermesPath;
    HERMES_HOME = "${home}/.hermes";
  };
  # Scripts do Hermes que estao no repo, com o Python do Nix no shebang.
  script =
    name: src:
    pkgs.writers.writePython3Bin name { doCheck = false; } (builtins.readFile src);
  cv = pkgs.writers.writePython3Bin "hermes-cv" {
    doCheck = false;
    libraries = with pkgs.python3Packages; [
      markdown
      weasyprint
    ];
  } (builtins.readFile ../../../scripts/hermes/hermes-cv);
in
{
  environment.systemPackages = [
    (script "hermes-books" ../../../scripts/hermes/hermes-books)
    (script "hermes-mail" ../../../scripts/hermes/hermes-mail)
    (pkgs.writers.writePython3Bin "vagas-buscar" {
      doCheck = false;
      libraries = [ pkgs.python3Packages.websockets ];
    } (builtins.readFile ../../../scripts/vagas-buscar))
    cv
    pkgs.poppler-utils
  ]
  # Bot Screen do Hermes: tela virtual com Chromium visivel, um perfil por agente.
  # Nada sobe no boot: a tela so abre quando um agente usa o navegador.
  ++ (with pkgs; [
    tigervnc
    xfwm4
    xfce4-panel
    xfdesktop
    xfce4-settings
    xauth
    xdpyinfo
    setxkbmap
    xprop
    dejavu_fonts
    chromium
    # Temas de icone do Bot Screen (o launcher procura em /usr/share/icons e ~/.icons).
    papirus-icon-theme
    adwaita-icon-theme
    numix-icon-theme-circle
  ]);

  # A NixOS nao tem /usr/share/icons: o link põe os temas onde o launcher do Bot Screen
  # procura. Sem ele o dock e a area de trabalho ficam sem icone.
  systemd.tmpfiles.rules = [
    "L+ /home/htr/.icons - - - - /run/current-system/sw/share/icons"
  ];

  # O navegador dos bots sai pelo IP de casa (SOCKS do `casa`): o IP do racknerd e barrado
  # no Cloudflare do Indeed, Glassdoor, Catho, Jooble e Vagas.com.br. A politica vale para
  # o navegador do agente e para o icone Browser do dock, e o resto da VPS segue direto.
  environment.etc."chromium/policies/managed/proxy-casa.json".text = builtins.toJSON {
    ProxyMode = "fixed_servers";
    ProxyServer = "socks5://100.112.62.47:1080";
    # A VPS e a tailnet continuam diretas: so o que e internet sai pelo casa.
    ProxyBypassRules = "localhost,127.0.0.1,::1,100.64.0.0/10,*.ts.net";
  };

  systemd.services.hermes-gateway = {
    description = "Hermes Agent Gateway - Messaging Platform Integration";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      StartLimitIntervalSec = 0;
      ConditionPathExists = hermesBin;
    };
    environment = hermesEnv // {
      HERMES_SUPERVISED_CHILD = "1";
    };
    serviceConfig = {
      Type = "simple";
      User = "htr";
      Group = "htr";
      WorkingDirectory = "${home}/.hermes";
      ExecStart = "${hermesBin} gateway run";
      ExecReload = "${pkgs.coreutils}/bin/kill -USR1 $MAINPID";
      ExecStop = "-${hermesBin} --run-module gateway.systemd_stop_mark";
      ExecStopPost = "-${hermesBin} --run-module gateway.cgroup_cleanup";
      Restart = "always";
      RestartSec = 5;
      RestartForceExitStatus = 75;
      SuccessExitStatus = 75;
      RestartPreventExitStatus = 78;
      KillMode = "mixed";
      KillSignal = "SIGTERM";
      TimeoutStopSec = 70;
      # Com o Bot Screen aberto, tela e Chromium somam de 1,1 a 1,5 GB ao gateway.
      MemoryHigh = "2560M";
      MemoryMax = "3G";
    };
  };

  # Reinicio diario: recarrega os MCPs stdio do gateway.
  systemd.services.hermes-gateway-restart = {
    description = "Reinicia o hermes-gateway (recarrega os MCPs stdio)";
    # No maximo 3 reinicios a cada 15 min, mesmo que o pedido se repita.
    unitConfig = {
      StartLimitIntervalSec = 900;
      StartLimitBurst = 3;
    };
    serviceConfig.Type = "oneshot";
    script = ''
      sleep 20
      ${pkgs.systemd}/bin/systemctl restart hermes-gateway.service
    '';
  };
  # O proprio Hermes pede reinicio sem sudo: date > ~/.hermes/reiniciar.pedido
  systemd.paths.hermes-gateway-restart = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathModified = "${home}/.hermes/reiniciar.pedido";
  };

  systemd.timers.hermes-gateway-restart = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:30:00 America/Sao_Paulo";
      Persistent = false;
    };
  };

  systemd.services.hermes-dashboard = {
    description = "Hermes Agent Dashboard";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "${home}/.local/bin/hermes";
    environment = hermesEnv;
    serviceConfig = {
      Type = "simple";
      User = "htr";
      Group = "htr";
      WorkingDirectory = "${home}/.hermes";
      ExecStart = "${home}/.local/bin/hermes dashboard --host 127.0.0.1 --port 9119 --no-open";
      Restart = "always";
      MemoryHigh = "600M";
      MemoryMax = "768M";
    };
  };

  systemd.services.opencode = {
    description = "OpenCode server";
    after = [
      "network-online.target"
      "tailscaled.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
      ConditionPathExists = "${home}/.opencode/bin/opencode";
    };
    environment = {
      HOME = home;
      PATH = lib.mkForce "${home}/.opencode/bin:${home}/.local/bin:/usr/local/bin:${sysPath}";
      TERM = "dumb";
    };
    serviceConfig = {
      Type = "simple";
      User = "htr";
      Group = "htr";
      WorkingDirectory = "${home}/homelab";
      ExecStart = "${home}/.opencode/bin/opencode serve --service";
      Restart = "on-failure";
      RestartSec = 5;
      SuccessExitStatus = 143;
    };
  };

  # Anytype do Geoffrey (decisao 31), como servico de usuario com lingering.
  systemd.user.services.anytype = {
    description = "Anytype";
    wantedBy = [ "default.target" ];
    unitConfig = {
      ConditionUser = "htr";
      ConditionFileIsExecutable = "${home}/.local/bin/anytype";
      StartLimitIntervalSec = 5;
      StartLimitBurst = 10;
    };
    serviceConfig = {
      ExecStart = "${home}/.local/bin/anytype serve";
      Restart = "always";
      RestartSec = 120;
    };
  };
}
