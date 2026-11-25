# Nextcloud na mesma imagem de antes, armazenamento primario no R2 (bucket htr-nextcloud).
# /srv/nextcloud/html guarda config/, data/ e themes/. O codigo vem da imagem no primeiro boot.
# O config.php aponta o banco para o nome do CNPG: o --add-host leva esse nome ao Postgres do host.
{ config, pkgs, ... }:
let
  image = "nextcloud:35.0.3-apache@sha256:8a7a65b8bae82a79568fec2ed9cf3e374a1944eda2a22ebe130d79463336fee3";
in
{
  virtualisation.oci-containers.containers.nextcloud = {
    inherit image;
    ports = [ "127.0.0.1:8081:80" ];
    volumes = [ "/srv/nextcloud/html:/var/www/html" ];
    environment = {
      NEXTCLOUD_TRUSTED_DOMAINS = "nuvem.htrlab.duckdns.org";
      OVERWRITEPROTOCOL = "https";
      TRUSTED_PROXIES = "10.89.0.0/24 127.0.0.1";
      PHP_MEMORY_LIMIT = "512M";
      PHP_UPLOAD_LIMIT = "4G";
      OBJECTSTORE_S3_BUCKET = "htr-nextcloud";
      OBJECTSTORE_S3_HOST = "8ef031572e6694f614275029be68313a.r2.cloudflarestorage.com";
      OBJECTSTORE_S3_PORT = "443";
      OBJECTSTORE_S3_SSL = "true";
      OBJECTSTORE_S3_REGION = "auto";
      OBJECTSTORE_S3_USEPATH_STYLE = "true";
      OBJECTSTORE_S3_AUTOCREATE = "false";
    };
    environmentFiles = [ config.sops.templates."nextcloud.env".path ];
    extraOptions = [
      "--network=apps"
      "--add-host=nextcloud-db-rw.nextcloud.svc.cluster.local:10.89.0.1"
    ];
  };
  systemd.services.podman-nextcloud = {
    after = [ "postgresql.service" ];
    wants = [ "postgresql.service" ];
  };

  sops.secrets."nextcloud_s3_key" = { };
  sops.secrets."nextcloud_s3_secret" = { };
  sops.templates."nextcloud.env".content = ''
    OBJECTSTORE_S3_KEY=${config.sops.placeholder."nextcloud_s3_key"}
    OBJECTSTORE_S3_SECRET=${config.sops.placeholder."nextcloud_s3_secret"}
  '';

  # cron.php a cada 5 min, como o container de cron do pod antigo.
  systemd.services.nextcloud-cron = {
    description = "Cron do Nextcloud";
    after = [ "podman-nextcloud.service" ];
    requires = [ "podman-nextcloud.service" ];
    serviceConfig.Type = "oneshot";
    script = "${pkgs.podman}/bin/podman exec -u www-data nextcloud php -f /var/www/html/cron.php";
  };
  systemd.timers.nextcloud-cron = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
    };
  };

  systemd.tmpfiles.rules = [ "d /srv/nextcloud/html 0750 33 33 -" ];
}
