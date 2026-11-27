# Metricas e alertas nativos: VictoriaMetrics, vmalert, Alertmanager (Telegram e Healthchecks),
# blackbox e Grafana. Os paineis do repo e o Node Exporter Full sao provisionados por arquivo.
# O historico recomeca do zero na migracao.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  probe = module: targets: {
    job_name = "probe-${if module == "http_2xx" then "https" else "dns"}";
    metrics_path = "/probe";
    params.module = [ module ];
    static_configs = [ { inherit targets; } ];
    relabel_configs = [
      {
        source_labels = [ "__address__" ];
        target_label = "__param_target";
      }
      {
        source_labels = [ "__param_target" ];
        target_label = "instance";
      }
      {
        target_label = "__address__";
        replacement = "127.0.0.1:9115";
      }
    ];
  };
  node = name: addr: {
    targets = [ "${addr}:9100" ];
    labels = {
      instance = name;
      node = name;
    };
  };

  nodeExporterFull = pkgs.fetchurl {
    url = "https://grafana.com/api/dashboards/1860/revisions/41/download";
    name = "node-exporter-full.json";
    hash = "sha256-EywgxEayjwNIGDvSmA/S56Ld49qrTSbIYFpeEXBJlTs=";
  };
  dashboards = pkgs.runCommand "grafana-dashboards" { } ''
    mkdir -p $out
    cp ${./dashboards}/*.json $out/
    cp ${nodeExporterFull} $out/node-exporter-full.json
  '';
  cred = name: "/run/credentials/alertmanager.service/${name}";
in
{
  services.victoriametrics = {
    enable = true;
    listenAddress = "127.0.0.1:8428";
    retentionPeriod = "90d";
    prometheusConfig = {
      global.scrape_interval = "30s";
      scrape_configs = [
        {
          job_name = "node";
          static_configs = [
            (node "racknerd" "127.0.0.1")
            (node "casa" "100.112.62.47")
            (node "pc-heito-wsl" "100.89.110.97")
          ];
        }
        {
          job_name = "victoriametrics";
          static_configs = [ { targets = [ "127.0.0.1:8428" ]; } ];
        }
        {
          job_name = "vmalert";
          static_configs = [ { targets = [ "127.0.0.1:8880" ]; } ];
        }
        {
          job_name = "alertmanager";
          static_configs = [ { targets = [ "127.0.0.1:9093" ]; } ];
        }
        {
          job_name = "caddy";
          static_configs = [ { targets = [ "127.0.0.1:2019" ]; } ];
        }
        {
          job_name = "comin";
          static_configs = [ { targets = [ "127.0.0.1:4243" ]; } ];
        }
        (probe "http_2xx" [
          "https://casa.tail76c1c6.ts.net"
          "https://home.tail76c1c6.ts.net"
          "https://grafana.tail76c1c6.ts.net"
          "https://pihole.tail76c1c6.ts.net/admin/"
          "https://nuvem.htrlab.duckdns.org"
          "https://audio.htrlab.duckdns.org"
          "https://pedidos.htrlab.duckdns.org"
          "https://securo.htrlab.duckdns.org"
        ])
        (probe "dns_github" [ "100.104.129.86:53" ])
      ];
    };
  };

  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = "127.0.0.1";
    configFile = pkgs.writeText "blackbox.yaml" (
      builtins.toJSON {
        modules = {
          http_2xx = {
            prober = "http";
            timeout = "10s";
            http = {
              preferred_ip_protocol = "ip4";
              follow_redirects = true;
            };
          };
          dns_github = {
            prober = "dns";
            timeout = "5s";
            dns = {
              query_name = "github.com";
              query_type = "A";
              transport_protocol = "udp";
              preferred_ip_protocol = "ip4";
              valid_rcodes = [ "NOERROR" ];
            };
          };
        };
      }
    );
  };

  services.vmalert.instances.homelab = {
    enable = true;
    settings = {
      "httpListenAddr" = "127.0.0.1:8880";
      "datasource.url" = "http://127.0.0.1:8428";
      "remoteWrite.url" = "http://127.0.0.1:8428";
      "remoteRead.url" = "http://127.0.0.1:8428";
      "notifier.url" = [ "http://127.0.0.1:9093" ];
      "external.url" = "https://grafana.tail76c1c6.ts.net";
    };
    rules = builtins.fromJSON (builtins.readFile ./alert-rules.json);
  };

  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9093;
    checkConfig = false;
    configuration = {
      # Tudo vai para o Ops do Hermes, que descarta duplicata e decide o que passar.
      # O backoff exponencial de alerta repetido fica no script da rota (alert-backoff.py):
      # o repeat_interval de 1h so da a ele a chance de reavisar.
      route = {
        receiver = "hermes";
        group_by = [
          "alertname"
          "instance"
        ];
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "1h";
        routes = [
          {
            receiver = "healthchecks";
            matchers = [ ''alertname="Watchdog"'' ];
            group_wait = "0s";
            group_interval = "1m";
            repeat_interval = "1m";
          }
          # Se a entrega ao Hermes falhar, o aviso vai direto ao Telegram.
          {
            receiver = "telegram";
            matchers = [ ''alertname="NotificacaoFalhou"'' ];
            repeat_interval = "6h";
          }
        ];
      };
      receivers = [
        {
          name = "hermes";
          webhook_configs = [
            {
              url = "http://127.0.0.1:8644/p/ops/webhooks/alertas";
              send_resolved = true;
              max_alerts = 30;
              http_config.http_headers."X-Gitlab-Token".files = [ (cred "hermes") ];
            }
          ];
        }
        {
          name = "telegram";
          telegram_configs = [
            {
              bot_token_file = cred "telegram";
              chat_id = 8568560413;
              parse_mode = "";
              send_resolved = true;
              message = ''{{ if eq .Status "firing" }}ALERTA [{{ .CommonLabels.severity }}]{{ else }}RESOLVIDO{{ end }}: {{ .CommonLabels.alertname }}
{{ range .Alerts }}- {{ .Annotations.summary }}
  {{ if .Labels.instance }}instancia: {{ .Labels.instance }}{{ end }}{{ if .Labels.job }} ({{ .Labels.job }}){{ end }}
{{ end }}'';
            }
          ];
        }
        {
          name = "healthchecks";
          webhook_configs = [
            {
              url_file = cred "healthchecks";
              send_resolved = false;
            }
          ];
        }
      ];
    };
  };
  systemd.services.alertmanager.serviceConfig.LoadCredential = [
    "telegram:${config.sops.secrets."alertmanager_telegram_token".path}"
    "healthchecks:${config.sops.secrets."alertmanager_healthchecks_url".path}"
    "hermes:${config.sops.secrets."alertmanager_hermes_webhook".path}"
  ];
  sops.secrets."alertmanager_telegram_token" = { };
  sops.secrets."alertmanager_healthchecks_url" = { };
  # Token da rota de alertas do Hermes (header X-Gitlab-Token). Legivel pelo htr para a
  # rota do Hermes usar o mesmo valor.
  sops.secrets."alertmanager_hermes_webhook" = {
    owner = "htr";
    mode = "0400";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        root_url = "https://grafana.tail76c1c6.ts.net";
        enable_gzip = true;
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets."grafana_admin_password".path}}";
        secret_key = "$__file{${config.sops.secrets."grafana_secret_key".path}}";
      };
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };
      users.default_language = "pt-BR";
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "VictoriaMetrics";
          uid = "victoriametrics";
          type = "prometheus";
          url = "http://127.0.0.1:8428";
          access = "proxy";
          isDefault = true;
        }
      ];
      dashboards.settings.providers = [
        {
          name = "homelab";
          folder = "Homelab";
          type = "file";
          disableDeletion = true;
          options.path = dashboards;
        }
      ];
    };
  };
  sops.secrets."grafana_admin_password".owner = "grafana";
  sops.secrets."grafana_secret_key".owner = "grafana";

  # Metricas da tailnet para o textfile collector do node-exporter (script do host antigo).
  systemd.services.tailscale-prometheus = {
    description = "Coleta metricas do Tailscale para o node-exporter";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    path = [
      config.services.tailscale.package
      pkgs.jq
      pkgs.coreutils
    ];
    serviceConfig.Type = "oneshot";
    script = builtins.readFile ../../scripts/tailscale-prometheus;
  };
  systemd.timers.tailscale-prometheus = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      AccuracySec = "5s";
    };
  };
}
