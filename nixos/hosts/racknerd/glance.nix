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
    { title = "Manga"; url = "https://manga.tail76c1c6.ts.net"; check-url = "http://127.0.0.1:4567/"; }
    { title = "VictoriaMetrics"; url = "https://metricas.tail76c1c6.ts.net"; check-url = "http://127.0.0.1:8428/health"; icon = "di:victoriametrics"; }
    { title = "Matter Hub"; url = "https://casa.tail76c1c6.ts.net:8443/"; icon = "di:matter"; }
  ];

  # CPU, RAM e disco do casa no formato do widget de server-stats.
  casaQuery = lib.concatStrings [
    ''label_replace(label_replace(100*(1-avg(rate(node_cpu_seconds_total{node="casa",mode="idle"}[5m]))),"nome","CPU","",""),"ordem","1","","")''
    ''or label_replace(label_replace(100*(1-node_memory_MemAvailable_bytes{node="casa"}/node_memory_MemTotal_bytes{node="casa"}),"nome","RAM","",""),"ordem","2","","")''
    ''or label_replace(label_replace(100*(1-node_filesystem_avail_bytes{node="casa",mountpoint="/",fstype="ext4"}/node_filesystem_size_bytes{node="casa",mountpoint="/",fstype="ext4"}),"nome","Disco","",""),"ordem","3","","")''
  ];

  configFile = (pkgs.formats.yaml { }).generate "glance.yml" {
    server = { host = "127.0.0.1"; port = 3003; };
    branding = { app-name = "homelab"; logo-text = "h"; hide-footer = true; };
    theme.disable-picker = true;
    pages = [
      {
        name = "Home";
        width = "wide";
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
              {
                type = "custom-api";
                title = "casa";
                cache = "30s";
                url = "http://127.0.0.1:8428/api/v1/query?query=" + lib.escapeURL casaQuery;
                template = ''
                  {{ range sortByInt "metric.ordem" "asc" (.JSON.Array "data.result") }}
                  <div class="margin-top-3">
                    <div class="flex justify-between items-end">
                      <div class="size-h5">{{ .String "metric.nome" }}</div>
                      <div class="color-highlight text-very-compact">{{ .Float "value.1" | printf "%.0f" }} <span class="color-base">%</span></div>
                    </div>
                    <div class="progress-bar progress-bar-combined">
                      <div class="progress-value" style="--percent: {{ .Float "value.1" | printf "%.0f" }}"></div>
                    </div>
                  </div>
                  {{ end }}
                '';
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
      {
        name = "Logins";
        width = "slim";
        columns = [
          {
            size = "full";
            widgets = [
              {
                type = "bookmarks";
                hide-header = true;
                groups = [
                  {
                    title = "Contas";
                    links = [
                      { title = "Senhas Google"; url = "https://passwords.google.com/"; icon = "di:google"; }
                      { title = "Google"; url = "https://myaccount.google.com/"; icon = "di:google"; }
                      { title = "Gmail principal"; url = "https://mail.google.com/mail/u/0/"; icon = "di:gmail"; }
                      { title = "Gmail jogos"; url = "https://mail.google.com/mail/u/1/"; icon = "di:gmail"; }
                      { title = "Hotmail"; url = "https://outlook.live.com/mail/"; icon = "di:microsoft-outlook"; }
                    ];
                  }
                  {
                    title = "Trabalho";
                    links = [
                      { title = "GitHub"; url = "https://github.com/login"; icon = "si:github"; }
                      { title = "Gitea agro-e"; url = "https://gitea.agro-e.com.br/user/login"; icon = "di:gitea"; }
                      { title = "LinkedIn"; url = "https://www.linkedin.com/login"; icon = "di:linkedin"; }
                    ];
                  }
                  {
                    title = "Infra";
                    links = [
                      { title = "Cloudflare"; url = "https://dash.cloudflare.com/login"; icon = "di:cloudflare"; }
                      { title = "DuckDNS"; url = "https://www.duckdns.org/"; icon = "di:duckdns"; }
                      { title = "Tailscale"; url = "https://login.tailscale.com/admin"; icon = "si:tailscale"; }
                    ];
                  }
                ];
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
