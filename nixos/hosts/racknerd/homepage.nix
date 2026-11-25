# Pagina inicial em https://home.tail76c1c6.ts.net. Roda com a rede do host para checar os apps em 127.0.0.1.
{ pkgs, ... }:
let
  conf = ./homepage;
in
{
  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:v2.8.0@sha256:019d8f063a7299e7c1c51ee4a70b692291809af3244894fbec2c2ac7d1f71b18";
    environment = {
      HOMEPAGE_ALLOWED_HOSTS = "home.tail76c1c6.ts.net";
      HOSTNAME = "127.0.0.1";
      PORT = "3002";
    };
    volumes = [
      "${conf}/settings.yaml:/app/config/settings.yaml:ro"
      "${conf}/services.yaml:/app/config/services.yaml:ro"
      "${conf}/widgets.yaml:/app/config/widgets.yaml:ro"
    ];
    extraOptions = [ "--network=host" ];
  };
}
