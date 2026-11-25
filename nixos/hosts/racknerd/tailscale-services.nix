# Nomes da tailnet (https://<nome>.tail76c1c6.ts.net) servidos pelo proprio no, como Tailscale Services.
# Exige que o racknerd tenha a tag dos servicos (ver nixos/README.md, virada).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  ts = "${config.services.tailscale.package}/bin/tailscale";
  services = {
    grafana = 3000;
    home = 3002;
    pihole = 8053;
    waha = 3001;
    prowlarr = 9696;
    transmission = 9091;
    metricas = 8428;
    securo-mcp = 8765;
  };
in
{
  systemd.services.tailscale-services = {
    description = "Tailscale Services e serve do no";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    # Com o tailscaled fora, falha em 2 min e tenta de novo, sem travar o deploy do comin.
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "2min";
      Restart = "on-failure";
      RestartSec = "30s";
    };
    path = [ pkgs.jq ];
    script = ''
      until ${ts} status --json | jq -e '.BackendState == "Running"' >/dev/null; do sleep 2; done
      ${lib.concatStrings (
        lib.mapAttrsToList (name: port: ''
          ${ts} serve --service=svc:${name} --https=443 --bg http://127.0.0.1:${toString port}
        '') services
      )}
      # No proprio: OpenCode (443) e dashboard do Hermes (8443).
      ${ts} serve --https=443 --bg http://127.0.0.1:49374
      ${ts} serve --https=8443 --bg http://127.0.0.1:9119
    '';
  };
}
