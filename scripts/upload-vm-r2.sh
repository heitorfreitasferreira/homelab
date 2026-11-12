#!/usr/bin/env bash
# Copia os dados da VM legada direto para o bucket R2 de migracao (a VM sobe a ~68 MB/s).
# Roda o rclone em container detached na VM. Credenciais: ~/.config/homelab/r2-migracao.env.
# Uso: scripts/upload-vm-r2.sh [copy|check]
set -euo pipefail

VM="htr@23.254.208.229"
MODE="${1:-copy}"
ENV_LOCAL="$HOME/.config/homelab/r2-migracao.env"

scp -q "$ENV_LOCAL" "$VM:.r2-migracao.env"
ssh -o BatchMode=yes "$VM" "chmod 600 ~/.r2-migracao.env"

# Same scope as backup-vm-legado.sh. Derived Immich data (thumbs, encoded-video) and caches are skipped.
ssh -o BatchMode=yes "$VM" bash -s -- "$MODE" <<'EOF'
set -euo pipefail
MODE="$1"
set -a; . ~/.r2-migracao.env; set +a
VOLS="n8n_n8n_data n8n_traefik_data firefly_firefly_iii_upload firefly_firefly_iii_db nextcloud_nextcloud nextcloud_db"
VOLMOUNTS=""
for v in $VOLS; do VOLMOUNTS="$VOLMOUNTS -v /var/lib/docker/volumes/$v/_data:/src/volumes/$v:ro"; done
docker rm -f rclone-migracao >/dev/null 2>&1 || true
docker run -d --name rclone-migracao --log-driver none \
  -v /home/htr:/src/home-htr:ro -v /path/to/heimdall/config:/src/heimdall-config:ro $VOLMOUNTS \
  -v /home/htr/rclone-log:/log \
  -e RCLONE_CONFIG_R2_TYPE=s3 -e RCLONE_CONFIG_R2_PROVIDER=Cloudflare \
  -e RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" -e RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" \
  -e RCLONE_CONFIG_R2_ENDPOINT="$R2_ENDPOINT" -e RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true \
  rclone/rclone:latest "$MODE" /src "r2:$R2_BUCKET/racknerd-20261112" \
    --exclude '/home-htr/lab/immich/postgres/**' \
    --exclude '/home-htr/lab/immich/library/thumbs/**' \
    --exclude '/home-htr/lab/immich/library/encoded-video/**' \
    --exclude '/home-htr/.cache/**' --exclude '/home-htr/.npm/**' \
    --exclude '/home-htr/rclone-log/**' --exclude '/home-htr/.r2-migracao.env' \
    --transfers 16 --checkers 32 --links --stats 30s --stats-one-line \
    --log-file "/log/$MODE.log" --log-level INFO
echo "container rclone-migracao iniciado ($MODE)"
EOF
