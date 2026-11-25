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
    { title = "Matter Hub"; url = "https://casa.tail76c1c6.ts.net:8443/"; icon = "di:matter"; }
    { title = "Waha"; url = "https://waha.tail76c1c6.ts.net/dashboard"; alt-status-codes = [ 401 ]; icon = "di:waha"; }
  ];

  # CPU, RAM e disco do casa no formato do widget de server-stats.
  casaQuery = lib.concatStrings [
    ''label_replace(label_replace(100*(1-avg(rate(node_cpu_seconds_total{node="casa",mode="idle"}[5m]))),"nome","CPU","",""),"ordem","1","","")''
    ''or label_replace(label_replace(100*(1-node_memory_MemAvailable_bytes{node="casa"}/node_memory_MemTotal_bytes{node="casa"}),"nome","RAM","",""),"ordem","2","","")''
    ''or label_replace(label_replace(100*(1-node_filesystem_avail_bytes{node="casa",mountpoint="/",fstype="ext4"}/node_filesystem_size_bytes{node="casa",mountpoint="/",fstype="ext4"}),"nome","Disco","",""),"ordem","3","","")''
  ];

  haUrl = "https://casa.htrlab.duckdns.org";
  haWidget = { title, jinja, template }: {
    type = "custom-api";
    inherit title template;
    cache = "30s";
    url = "${haUrl}/api/template";
    method = "POST";
    body-type = "json";
    headers.Authorization = "Bearer \${HA_TOKEN}";
    body.template = jinja;
  };

  energyCard = haWidget {
    title = "Energia";
    jinja = ''
      {% set pv = states('sensor.inversor_pv_power') | float(0) %}
      {% set today = states('sensor.inversor_today_production') | float(0) %}
      {% set forecast = states('sensor.casa_energy_production_today') | float(0) %}
      {% set temp = states('sensor.inversor_dc_temperature') | float(0) %}
      {
        "pv": {{ pv | round(0) }},
        "today": {{ today | round(1) }},
        "forecast": {{ forecast | round(1) }},
        "temp": {{ temp | round(0) }},
        "state": "{{ states('sensor.inversor_device_state') }}"
      }
    '';
    template = ''
      <div class="flex justify-between items-end">
        <div>
          <div class="color-highlight size-h2">{{ div (.JSON.Float "pv") 1000 | printf "%.1f" }} <span class="size-h5 color-base">kW</span></div>
          <div class="size-h6 color-paragraph">agora</div>
        </div>
        <div class="text-right">
          <div class="color-highlight size-h4">{{ .JSON.Float "today" | printf "%.1f" }} <span class="size-h6 color-base">kWh</span></div>
          <div class="size-h6 color-paragraph">hoje</div>
        </div>
      </div>
      <div class="flex justify-between margin-top-15 size-h6 color-paragraph">
        <div>previsao {{ .JSON.Float "forecast" | printf "%.1f" }} kWh</div>
        <div>inversor {{ .JSON.Float "temp" | printf "%.0f" }} °C, {{ .JSON.String "state" }}</div>
      </div>
    '';
  };

  casaCard = haWidget {
    title = "Casa agora";
    jinja = ''
      {% set room = states('sensor.temperatura_quarto') | float(0) %}
      {% set lights = states.light | selectattr('state','eq','on') | list | count %}
      {% set battery = state_attr('vacuum.robo_aspirador','battery_level') | int(0) %}
      {
        "room": {{ room | round(1) }},
        "lights": {{ lights }},
        "vacuum": "{{ states('vacuum.robo_aspirador') }}",
        "battery": {{ battery }},
        "heitor": "{{ states('person.heitor_freitas_ferreira') }}"
      }
    '';
    template = ''
      <div class="flex justify-between items-end">
        <div>
          <div class="color-highlight size-h2">{{ .JSON.Float "room" | printf "%.1f" }} <span class="size-h5 color-base">°C</span></div>
          <div class="size-h6 color-paragraph">quarto</div>
        </div>
        <div class="text-right">
          <div class="color-highlight size-h3">{{ .JSON.Int "lights" }}</div>
          <div class="size-h6 color-paragraph">luzes acesas</div>
        </div>
      </div>
      <ul class="list list-gap-10 margin-top-15">
        <li class="flex justify-between">
          <span>aspirador</span>
          <span class="color-highlight">{{ if eq (.JSON.String "vacuum") "docked" }}na base{{ else }}{{ .JSON.String "vacuum" }}{{ end }}, {{ .JSON.Int "battery" }}%</span>
        </li>
        <li class="flex justify-between">
          <span>Heitor</span>
          <span class="color-highlight">{{ if eq (.JSON.String "heitor") "home" }}em casa{{ else }}fora{{ end }}</span>
        </li>
      </ul>
    '';
  };

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
              {
                type = "dns-stats";
                service = "pihole-v6";
                url = "http://127.0.0.1:8053";
                password = "\${PIHOLE_PASSWORD}";
                hour-format = "24h";
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
        name = "Casa";
        width = "slim";
        columns = [
          {
            size = "small";
            widgets = [
              { type = "weather"; location = "Uberlandia, Brazil"; units = "metric"; hour-format = "24h"; }
              { type = "calendar"; first-day-of-week = "monday"; }
            ];
          }
          {
            size = "full";
            widgets = [ energyCard casaCard ];
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
                      { title = "Senhas"; url = "https://passwords.google.com/"; icon = "di:google"; }
                      { title = "Google"; url = "https://myaccount.google.com/"; icon = "di:google"; }
                      { title = "Gmail pessoal"; url = "https://mail.google.com/mail/u/0/"; icon = "di:gmail"; }
                      { title = "Gmail profissional"; url = "https://mail.google.com/mail/u/1/"; icon = "di:gmail"; }
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
  sops.secrets."ha_token" = { };
  sops.templates."glance.env".content = ''
    HA_TOKEN=${config.sops.placeholder."ha_token"}
    PIHOLE_PASSWORD=${config.sops.placeholder."pihole_password"}
  '';

  virtualisation.oci-containers.containers.glance = {
    image = "docker.io/glanceapp/glance:v0.8.8@sha256:4d7445bc7971836858ffddee5d7501f1efbabb6e694a45b1dde1a789bb1943bb";
    environmentFiles = [ config.sops.templates."glance.env".path ];
    volumes = [
      "${configFile}:/app/config/glance.yml:ro"
      "/run/podman/podman.sock:/var/run/docker.sock"
      "/:/host:ro"
    ];
    extraOptions = [ "--network=host" ];
  };
}
