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
  ];

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
      # O gateway chegava ao teto de 1G e ia para swap.
      MemoryMax = "1536M";
    };
  };

  # Reinicio diario: recarrega os MCPs stdio do gateway.
  systemd.services.hermes-gateway-restart = {
    description = "Reinicia o hermes-gateway (recarrega os MCPs stdio)";
    serviceConfig.Type = "oneshot";
    script = ''
      sleep 20
      ${pkgs.systemd}/bin/systemctl restart hermes-gateway.service
    '';
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
