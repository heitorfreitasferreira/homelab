#!/usr/bin/env bash
# Backup completo da VM legada (Docker Compose) para este PC antes do reinstall.
# Le tudo via Docker (htr esta no grupo docker), sem sudo.
# RTT de ~185 ms limita um stream TCP a ~200 KB/s, entao o rsync roda em N streams paralelos
# com listas de arquivos balanceadas por tamanho. Idempotente: pode rodar de novo para retomar.
# Uso: scripts/backup-vm-legado.sh <destino-local> [streams]
set -euo pipefail

VM="htr@23.254.208.229"
DEST="${1:?uso: $0 <destino-local> [streams]}"
STREAMS="${2:-16}"
SSH=(ssh -o BatchMode=yes -o ServerAliveInterval=30 "$VM")
MOUNTS='-v /home/htr:/home/htr:ro -v /path/to/heimdall:/path/to/heimdall:ro -v /var/lib/docker/volumes:/var/lib/docker/volumes:ro'
RSYNC_REMOTE="docker run --rm -i $MOUNTS instrumentisto/rsync-ssh rsync"
VOLUMES="n8n_n8n_data n8n_traefik_data firefly_firefly_iii_upload firefly_firefly_iii_db nextcloud_nextcloud nextcloud_db"
LISTS="$DEST/.lists"

mkdir -p "$DEST/meta" "$DEST/root" "$LISTS"

echo "== metadados"
"${SSH[@]}" 'docker ps -a --no-trunc' > "$DEST/meta/docker-ps.txt"
"${SSH[@]}" 'docker inspect $(docker ps -aq)' > "$DEST/meta/docker-inspect.json"
"${SSH[@]}" 'docker volume ls' > "$DEST/meta/docker-volumes.txt"
"${SSH[@]}" 'crontab -l' > "$DEST/meta/crontab-htr.txt"
"${SSH[@]}" 'docker exec immich_postgres psql -U postgres -d immich -Atc "select type, count(*) from asset group by type"' > "$DEST/meta/immich-asset-counts.txt"

echo "== dumps no disco da VM (~/dumps), copiados junto no rsync"
"${SSH[@]}" 'mkdir -p ~/dumps && docker exec immich_postgres pg_dumpall --clean --if-exists -U postgres | gzip > ~/dumps/immich-pg_dumpall.sql.gz.tmp && mv ~/dumps/immich-pg_dumpall.sql.gz.tmp ~/dumps/immich-pg_dumpall.sql.gz'
"${SSH[@]}" 'docker exec firefly_iii_db sh -c "mariadb-dump -u\"\$MYSQL_USER\" -p\"\$MYSQL_PASSWORD\" --single-transaction --routines \"\$MYSQL_DATABASE\"" | gzip > ~/dumps/firefly-mariadb.sql.gz.tmp && mv ~/dumps/firefly-mariadb.sql.gz.tmp ~/dumps/firefly-mariadb.sql.gz'

echo "== lista de arquivos (tamanho + caminho)"
# Excluidos: postgres do immich (coberto pelo dump), derivados regeneraveis (thumbs, encoded-video), caches.
VOL_PATHS=""
for v in $VOLUMES; do VOL_PATHS="$VOL_PATHS /var/lib/docker/volumes/$v/_data"; done
"${SSH[@]}" "docker run --rm $MOUNTS alpine find /home/htr /path/to/heimdall/config $VOL_PATHS \
  \( -path /home/htr/lab/immich/postgres -o -path /home/htr/lab/immich/library/thumbs \
     -o -path /home/htr/lab/immich/library/encoded-video -o -path /home/htr/.cache -o -path /home/htr/.npm \) -prune \
  -o \( -type f -o -type l \) -exec stat -c '%s %n' {} +" > "$LISTS/all.txt"
echo "   $(wc -l < "$LISTS/all.txt") arquivos, $(awk '{s+=$1} END {printf "%.1f GB", s/1e9}' "$LISTS/all.txt")"

# Balanceamento guloso: maior arquivo vai para a lista com menor soma.
rm -f "$LISTS"/chunk.*
sort -rn "$LISTS/all.txt" | awk -v n="$STREAMS" -v dir="$LISTS" '
  { min=0; for (i=1;i<n;i++) if (sum[i] < sum[min]) min=i
    sum[min]+=$1; p=$0; sub(/^[0-9]+ \//, "", p); print p > (dir "/chunk." min) }'

echo "== rsync em $(ls "$LISTS"/chunk.* | wc -l) streams"
pids=()
for list in "$LISTS"/chunk.*; do
  rsync -rltH --partial --files-from="$list" --rsync-path="$RSYNC_REMOTE" \
    "$VM:/" "$DEST/root/" > "$list.log" 2>&1 &
  pids+=($!)
done
fail=0
for p in "${pids[@]}"; do wait "$p" || fail=1; done
if [ "$fail" -ne 0 ]; then echo "FALHA em algum stream: ver $LISTS/chunk.*.log"; exit 1; fi
echo "== ok"
