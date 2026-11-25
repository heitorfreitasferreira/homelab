# WAHA (WhatsApp, motor GOWS), usado pelo vagas. A sessao em /srv/waha/sessions evita reescanear o QR.
# O redis divide a rede do container do waha, como o sidecar do pod: o waha o acha em localhost.
{ config, ... }:
{
  virtualisation.oci-containers.containers = {
    waha = {
      image = "devlikeapro/waha:gows@sha256:1f7faeb0227ad5edb5711f7058bfce807ea65e5f92234af0778e4db140f6eb46";
      ports = [ "127.0.0.1:3001:3000" ];
      volumes = [ "/srv/waha/sessions:/app/.sessions" ];
      environment = {
        WHATSAPP_DEFAULT_ENGINE = "GOWS";
        WAHA_APPS_ENABLED = "True";
        WAHA_DASHBOARD_ENABLED = "true";
        WAHA_DASHBOARD_USERNAME = "admin";
        WHATSAPP_SWAGGER_ENABLED = "false";
        WAHA_API_KEY_EXCLUDE_PATH = "health,ping";
        TZ = "America/Sao_Paulo";
        WAHA_EVENTS_DOWNLOAD_MEDIA = "false";
        WAHA_API_DOWNLOAD_MEDIA = "false";
        WAHA_GOWS_DEVICE_REQUIRE_FULL_SYNC = "false";
        WAHA_GOWS_DEVICE_HISTORY_SYNC_FULL_SYNC_DAYS_LIMIT = "30";
        WAHA_GOWS_DEVICE_HISTORY_SYNC_RECENT_SYNC_DAYS_LIMIT = "30";
        WAHA_GOWS_DEVICE_HISTORY_SYNC_INITIAL_SYNC_MAX_MESSAGES_PER_CHAT = "200";
      };
      environmentFiles = [ config.sops.templates."waha.env".path ];
      extraOptions = [
        "--network=apps"
        "--cap-drop=ALL"
        "--security-opt=no-new-privileges"
        "--memory=768m"
      ];
    };
    waha-redis = {
      image = "docker.io/library/redis:8-alpine@sha256:7958cfbb9d152f87dadfbc89f1b0b15938f0b81ff8982feb327476f4911935c3";
      cmd = [
        "redis-server"
        "--save"
        ""
        "--appendonly"
        "no"
      ];
      dependsOn = [ "waha" ];
      extraOptions = [
        "--network=container:waha"
        "--memory=64m"
      ];
    };
  };

  sops.secrets."waha_api_key" = { };
  sops.secrets."waha_dashboard_password" = { };
  sops.templates."waha.env".content = ''
    WAHA_API_KEY=${config.sops.placeholder."waha_api_key"}
    WAHA_API_KEY_PLAIN=${config.sops.placeholder."waha_api_key"}
    WAHA_DASHBOARD_PASSWORD=${config.sops.placeholder."waha_dashboard_password"}
  '';

  systemd.tmpfiles.rules = [ "d /srv/waha/sessions 0755 root root -" ];
}
