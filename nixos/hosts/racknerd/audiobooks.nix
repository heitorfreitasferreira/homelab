# Audiobooks: audiobookshelf (biblioteca), readmeabook (pedidos), prowlarr (indexadores) e transmission.
# O banco do readmeabook guarda os enderecos do cluster antigo (<app>.audiobookshelf.svc.cluster.local):
# os aliases de rede mantem esses nomes validos sem mexer nos dados.
# Os audios nao entram no backup: o transmission rebaixa pelos .torrent guardados em sua config.
{ ... }:
let
  d = "/srv/audiobooks";
  ids = {
    PUID = "1000";
    PGID = "1000";
    TZ = "America/Sao_Paulo";
  };
  alias = name: [
    "--network=apps"
    "--network-alias=${name}.audiobookshelf.svc.cluster.local"
    "--network-alias=${name}.audiobookshelf.svc"
  ];
in
{
  virtualisation.oci-containers.containers = {
    audiobookshelf = {
      image = "ghcr.io/advplyr/audiobookshelf@sha256:60064c23f32fd9099fd39e82c5132c51701d1221135bbca04cd099b589e1edc3";
      ports = [ "127.0.0.1:13378:80" ];
      environment = {
        TZ = "America/Sao_Paulo";
        PORT = "80";
      };
      volumes = [
        "${d}/abs-config:/config"
        "${d}/abs-metadata:/metadata"
        "${d}/library:/audiobooks"
      ];
      extraOptions = alias "audiobookshelf";
    };
    prowlarr = {
      image = "lscr.io/linuxserver/prowlarr@sha256:45117ba8439e2337a92ffe38a451a4dafc0be771754d05d88cdf102419d09646";
      ports = [ "127.0.0.1:9696:9696" ];
      environment = ids;
      volumes = [ "${d}/prowlarr:/config" ];
      extraOptions = alias "prowlarr";
    };
    transmission = {
      image = "lscr.io/linuxserver/transmission@sha256:5baf08cd73a566699f35baad3c4a84ba7d7057220566c5fb29969bf2292dc2ff";
      ports = [ "127.0.0.1:9091:9091" ];
      environment = ids // {
        TRANSMISSION_DOWNLOAD_DIR = "/downloads";
        TRANSMISSION_INCOMPLETE_DIR_ENABLED = "false";
      };
      volumes = [
        "${d}/transmission:/config"
        "${d}/downloads:/downloads"
        "${d}/library:/audiobooks"
      ];
      extraOptions = alias "transmission";
    };
    readmeabook = {
      image = "ghcr.io/kikootwo/readmeabook@sha256:3c4e18563b3e22c7b67bcf3b323e81fda840159ea6c71eee91ab13a2d49b0cf1";
      ports = [ "127.0.0.1:3030:3030" ];
      environment = ids // {
        PUBLIC_URL = "https://pedidos.htrlab.duckdns.org";
        LOG_LEVEL = "info";
      };
      volumes = [
        "${d}/readmeabook/config:/app/config"
        "${d}/readmeabook/cache:/app/cache"
        "${d}/readmeabook/pgdata:/var/lib/postgresql/data"
        "${d}/readmeabook/redis:/var/lib/redis"
        "${d}/downloads:/downloads"
        "${d}/library:/media/audiobooks"
      ];
      dependsOn = [
        "prowlarr"
        "transmission"
        "audiobookshelf"
      ];
      extraOptions = alias "readmeabook";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${d} 0755 1000 1000 -"
    "d ${d}/library 0755 1000 1000 -"
    "d ${d}/downloads 0755 1000 1000 -"
    "d ${d}/abs-config 0755 root root -"
    "d ${d}/abs-metadata 0755 root root -"
    "d ${d}/prowlarr 0755 1000 1000 -"
    "d ${d}/transmission 0755 1000 1000 -"
    "d ${d}/readmeabook 0755 1000 1000 -"
  ];
}
