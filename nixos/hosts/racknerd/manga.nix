# Manga: Suwayomi (Tachidesk) baixa, guarda e serve. O Mihon do celular le pelo
# plugin Suwayomi. Os CBZ ficam no volume do app: rebaixaveis, fora do backup.
{ ... }:
let
  d = "/srv/manga";
in
{
  virtualisation.oci-containers.containers.suwayomi = {
    image = "ghcr.io/suwayomi/suwayomi-server@sha256:f87c945e76240adcb305f75c6fdf111d3917cd11834bdb1db5e95796778d4260";
    ports = [ "127.0.0.1:4567:4567" ];
    environment = {
      TZ = "America/Sao_Paulo";
      EXTENSION_STORES = ''["https://github.com/keiyoushi/extensions/raw/repo/index.pb"]'';
    };
    volumes = [ "${d}/data:/home/suwayomi/.local/share/Tachidesk" ];
  };

  systemd.tmpfiles.rules = [
    "d ${d} 0755 1000 1000 -"
    "d ${d}/data 0755 1000 1000 -"
  ];
}
