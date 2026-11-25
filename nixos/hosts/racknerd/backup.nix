# Copia diaria cifrada no R2 com restic: dados dos apps, home do htr e estado da Tailscale.
# Antes de cada copia: dumps do Postgres (o nativo e o embutido no readmeabook) e
# snapshots consistentes dos SQLite que ficam abertos o tempo todo.
# O Postgres nativo tambem tem WAL continuo pelo wal-g (postgres.nix).
{ config, pkgs, ... }:
let
  dumps = "/var/backup";
  sqliteSnap = pkgs.writeShellScript "sqlite-snapshots" ''
    set -eu
    out=${dumps}/sqlite
    mkdir -p "$out"
    for f in \
      /home/htr/.hermes/state.db \
      /home/htr/.hermes/kanban.db \
      /home/htr/.hermes/shared-state.db \
      /srv/audiobooks/abs-config/absdatabase.sqlite \
      /srv/audiobooks/prowlarr/prowlarr.db \
      /srv/pihole/etc/pihole-FTL.db; do
      [ -f "$f" ] || continue
      n=$(echo "$f" | tr / _)
      ${pkgs.sqlite}/bin/sqlite3 "file:$f?mode=ro" ".backup '$out/$n'"
    done
  '';
in
{
  services.postgresqlBackup = {
    enable = true;
    databases = [
      "app"
      "securo"
    ];
    location = "${dumps}/postgresql";
    compression = "zstd";
    startAt = "*-*-* 03:00:00";
  };

  services.restic.backups.r2 = {
    initialize = true;
    repository = "s3:https://8ef031572e6694f614275029be68313a.r2.cloudflarestorage.com/htr-backups/restic/racknerd";
    passwordFile = config.sops.secrets."restic_password".path;
    environmentFile = config.sops.templates."restic.env".path;
    paths = [
      "/srv"
      "/home/htr"
      "/var/lib/tailscale"
      dumps
    ];
    exclude = [
      # Reinstalaveis ou rebaixaveis.
      "/srv/audiobooks/library"
      "/srv/audiobooks/downloads"
      "/srv/audiobooks/readmeabook/pgdata"
      "/srv/nextcloud/html/apps"
      "/srv/nextcloud/html/core"
      "/srv/nextcloud/html/3rdparty"
      "/srv/nextcloud/html/dist"
      "/srv/nextcloud/html/lib"
      "/srv/nextcloud/html/data/nextcloud.log"
      "/home/htr/.hermes/hermes-agent"
      "/home/htr/.hermes/tools"
      "/home/htr/.hermes/installs"
      "/home/htr/.hermes/cache"
      "/home/htr/.cache"
      "/home/htr/.npm"
      "/home/htr/.opencode"
      "/home/htr/.local/share/claude"
      "/home/htr/.local/share/uv"
    ];
    backupPrepareCommand = ''
      set -eu
      ${sqliteSnap}
      mkdir -p ${dumps}/readmeabook
      ${pkgs.podman}/bin/podman exec readmeabook su postgres -c 'pg_dump -Fc -d readmeabook' \
        > ${dumps}/readmeabook/readmeabook.dump.tmp
      mv ${dumps}/readmeabook/readmeabook.dump.tmp ${dumps}/readmeabook/readmeabook.dump
    '';
    timerConfig = {
      OnCalendar = "*-*-* 03:30:00";
      Persistent = true;
      RandomizedDelaySec = "10m";
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };

  sops.secrets."restic_password" = { };
  sops.templates."restic.env".content = ''
    AWS_ACCESS_KEY_ID=${config.sops.placeholder."r2_backups_access_key_id"}
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."r2_backups_secret_access_key"}
    AWS_DEFAULT_REGION=auto
  '';

  # O postgresqlBackup nao cria o diretorio de destino e o servico roda como postgres.
  # /var/backup precisa de travessia para o postgres chegar em postgresql/ (0700 dele).
  systemd.tmpfiles.rules = [
    "d ${dumps} 0755 root root -"
    "d ${dumps}/postgresql 0700 postgres postgres -"
    "d ${dumps}/readmeabook 0750 root root -"
    "d ${dumps}/sqlite 0750 root root -"
  ];
}
