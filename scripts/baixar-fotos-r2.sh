#!/usr/bin/env bash
# Baixa os originais do Immich do bucket de migracao (R2) para este PC, para importar no Ente.
# Credenciais: ~/.config/homelab/r2-migracao.env. Idempotente: rodar de novo retoma e confere checksums.
# Uso: scripts/baixar-fotos-r2.sh [destino]
set -euo pipefail

DEST="${1:-$HOME/backups/immich-originais}"
SRC="racknerd-20261112/home-htr/lab/immich/library/library"
ENV_FILE="$HOME/.config/homelab/r2-migracao.env"

mkdir -p "$DEST"
set -a; . "$ENV_FILE"; set +a

exec docker run --rm --log-driver none -u "$(id -u):$(id -g)" \
  -v "$DEST:/out" \
  -e RCLONE_CONFIG_R2_TYPE=s3 -e RCLONE_CONFIG_R2_PROVIDER=Cloudflare \
  -e RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" \
  -e RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" \
  -e RCLONE_CONFIG_R2_ENDPOINT="$R2_ENDPOINT" \
  rclone/rclone:latest copy "r2:$R2_BUCKET/$SRC" /out \
  --transfers 16 --checkers 32 --checksum --stats 30s --stats-one-line --log-level INFO
