# Um Postgres 17 nativo para Nextcloud (banco e usuario "app", herdados do CNPG) e Securo (pgvector).
# WAL continuo e base diaria no R2 com wal-g, retencao de 30 bases (decisao 12).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  pg = config.services.postgresql.package;
  walg = pkgs.writeShellScript "wal-g" ''
    set -a
    . ${config.sops.templates."wal-g.env".path}
    set +a
    exec ${pkgs.wal-g}/bin/wal-g "$@"
  '';
in
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    extensions = ps: [ ps.pgvector ];
    enableTCPIP = true;
    settings = {
      shared_buffers = "128MB";
      max_connections = 60;
      wal_level = "replica";
      archive_mode = "on";
      archive_command = "${walg} wal-push %p";
      archive_timeout = "15min";
    };
    # Os containers entram pela rede apps. Fora dela so o socket local.
    authentication = lib.mkAfter ''
      host all all 10.89.0.0/24 scram-sha-256
    '';
    ensureDatabases = [
      "app"
      "securo"
    ];
    ensureUsers = [
      {
        name = "app";
        ensureDBOwnership = true;
      }
      {
        name = "securo";
        ensureDBOwnership = true;
      }
    ];
  };

  # Senhas declarativas: aplica as do sops a cada boot.
  systemd.services.postgresql-passwords = {
    description = "Senhas dos usuarios do Postgres";
    after = [ "postgresql-setup.service" "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      for u in app securo; do
        f=${config.sops.secrets."pg_password_app".path}
        [ "$u" = securo ] && f=${config.sops.secrets."pg_password_securo".path}
        [ -s "$f" ] || { echo "secret vazio: $f" >&2; exit 1; }
        printf "ALTER ROLE %s PASSWORD :'pw';\n" "$u" | ${pg}/bin/psql -v ON_ERROR_STOP=1 -v pw="$(cat "$f")" -d postgres
      done
    '';
  };

  sops.secrets."pg_password_app".owner = "postgres";
  sops.secrets."pg_password_securo".owner = "postgres";
  sops.secrets."r2_backups_access_key_id" = { };
  sops.secrets."r2_backups_secret_access_key" = { };
  sops.templates."wal-g.env" = {
    owner = "postgres";
    content = ''
      WALG_S3_PREFIX=s3://htr-backups/pg/racknerd
      AWS_ENDPOINT=https://8ef031572e6694f614275029be68313a.r2.cloudflarestorage.com
      AWS_REGION=auto
      AWS_S3_FORCE_PATH_STYLE=true
      AWS_ACCESS_KEY_ID=${config.sops.placeholder."r2_backups_access_key_id"}
      AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."r2_backups_secret_access_key"}
      WALG_COMPRESSION_METHOD=zstd
      PGHOST=/run/postgresql
      PGUSER=postgres
    '';
  };

  systemd.services.wal-g-backup = {
    description = "Base diaria do Postgres no R2 (wal-g) e retencao de 30";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };
    script = ''
      ${walg} backup-push ${config.services.postgresql.dataDir}
      ${walg} delete retain FULL 30 --confirm
    '';
  };
  systemd.timers.wal-g-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
    };
  };

  # Metricas do arquivamento do WAL e do pg_wal para o textfile collector do node-exporter.
  # setpriv porque o psql precisa rodar como postgres e o arquivo e escrito como root.
  systemd.services.postgres-metrics = {
    description = "Metricas do Postgres para o node-exporter";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    serviceConfig = {
      Type = "oneshot";
      path = [ pkgs.coreutils ];
    };
    script = ''
      set -eu
      out=/var/lib/prometheus/node-exporter/postgres.prom
      tmp="$out.tmp.$$"
      trap 'rm -f "$tmp"' EXIT
      as_postgres="${pkgs.util-linux}/bin/setpriv --reuid=postgres --regid=postgres --init-groups"

      failed=$($as_postgres ${pg}/bin/psql -At -c 'select failed_count from pg_stat_archiver' postgres)
      last=$($as_postgres ${pg}/bin/psql -At -c "select coalesce(extract(epoch from last_failed_time), 0)::bigint from pg_stat_archiver" postgres)
      wal=$($as_postgres ${pg}/bin/psql -At -c 'select coalesce(sum(size), 0) from pg_ls_waldir()' postgres)

      {
        echo "# HELP pg_archiver_failed_total Tentativas de arquivamento do WAL que falharam."
        echo "# TYPE pg_archiver_failed_total counter"
        echo "pg_archiver_failed_total $failed"
        echo "# HELP pg_archiver_last_failed_timestamp_seconds Ultima falha de arquivamento do WAL, 0 se nunca falhou."
        echo "# TYPE pg_archiver_last_failed_timestamp_seconds gauge"
        echo "pg_archiver_last_failed_timestamp_seconds $last"
        echo "# HELP pg_wal_bytes Bytes em pg_wal."
        echo "# TYPE pg_wal_bytes gauge"
        echo "pg_wal_bytes $wal"
      } > "$tmp"
      chmod 0644 "$tmp"
      mv "$tmp" "$out"
    '';
  };
  systemd.timers.postgres-metrics = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
    };
  };
}
