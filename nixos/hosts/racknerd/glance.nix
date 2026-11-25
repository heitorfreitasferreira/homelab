# Pagina inicial em https://home.tail76c1c6.ts.net. Sem banco: a config e gerada
# do Nix. Os servicos publicos saem do Caddy, entao vhost novo aparece sozinho.
{ config, lib, pkgs, ... }:
let
  publicMeta = {
    nuvem = { title = "Nextcloud"; icon = "di:nextcloud"; };
    audio = { title = "Audiobookshelf"; icon = "di:audiobookshelf"; };
    pedidos = { title = "ReadMeABook"; icon = "di:readmeabook"; };
    securo = { title = "Securo"; icon = "https://securo.htrlab.duckdns.org/favicon.ico"; };
    casa = { title = "Home Assistant"; icon = "di:home-assistant"; };
  };
  publicSites = lib.mapAttrsToList (host: _:
    let
      label = lib.removeSuffix ".htrlab.duckdns.org" host;
      meta = publicMeta.${label} or { title = label; };
    in
    { title = meta.title; url = "https://${host}"; }
    // lib.optionalAttrs (meta ? icon) { inherit (meta) icon; }
  ) config.services.caddy.virtualHosts;

  tailnetSites = [
    { title = "Grafana"; url = "https://grafana.tail76c1c6.ts.net"; check-url = "http://127.0.0.1:3000/api/health"; icon = "di:grafana"; }
    { title = "Pi-hole"; url = "https://pihole.tail76c1c6.ts.net/admin/"; check-url = "http://127.0.0.1:8053/admin/"; icon = "di:pi-hole"; timeout = "5s"; alt-status-codes = [ 302 ]; }
    { title = "Prowlarr"; url = "https://prowlarr.tail76c1c6.ts.net"; check-url = "http://127.0.0.1:9696/ping"; icon = "di:prowlarr"; }
    { title = "Transmission"; url = "https://transmission.tail76c1c6.ts.net"; check-url = "http://127.0.0.1:9091/transmission/web/"; icon = "di:transmission"; }
    { title = "VictoriaMetrics"; url = "https://metricas.tail76c1c6.ts.net"; check-url = "http://127.0.0.1:8428/health"; icon = "di:victoriametrics"; }
  ];

  configFile = (pkgs.formats.yaml { }).generate "glance.yml" {
    server = { host = "127.0.0.1"; port = 3003; };
    branding = { app-name = "homelab"; logo-text = "h"; hide-footer = true; };
    theme.disable-picker = true;
    pages = [
      {
        name = "Home";
        width = "wide";
        hide-desktop-navigation = true;
        columns = [
          {
            size = "small";
            widgets = [
              {
                type = "server-stats";
                servers = [
                  {
                    type = "local";
                    name = "racknerd";
                    hide-mountpoints-by-default = true;
                    mountpoints."/host" = { name = "Root"; hide = false; };
                  }
                ];
              }
              { type = "clock"; hour-format = "24h"; }
            ];
          }
          {
            size = "full";
            widgets = [
              {
                type = "monitor";
                title = "Servicos";
                cache = "1m";
                sites = publicSites ++ tailnetSites;
              }
            ];
          }
          {
            size = "small";
            widgets = [
              {
                type = "docker-containers";
                title = "Containers";
                format-container-names = true;
              }
            ];
          }
        ];
      }
    ];
  };
in
{
  virtualisation.oci-containers.containers.glance = {
    image = "docker.io/glanceapp/glance:v0.8.8@sha256:4d7445bc7971836858ffddee5d7501f1efbabb6e694a45b1dde1a789bb1943bb";
    volumes = [
      "${configFile}:/app/config/glance.yml:ro"
      "/run/podman/podman.sock:/var/run/docker.sock"
      "/:/host:ro"
    ];
    extraOptions = [ "--network=host" ];
  };
}
