#!/usr/bin/env bash
# Confere o backup local contra a VM: nome + tamanho de todo arquivo, sha256 de uma amostra
# dos originais do Immich e integridade dos dumps.
# Uso: scripts/verificar-backup-legado.sh <destino-local>
set -euo pipefail

VM="htr@23.254.208.229"
DEST="${1:?uso: $0 <destino-local>}"
ROOT="$DEST/root"
MOUNTS='-v /home/htr:/home/htr:ro -v /path/to/heimdall:/path/to/heimdall:ro -v /var/lib/docker/volumes:/var/lib/docker/volumes:ro'
fail=0

echo "== nome + tamanho (lista gerada no backup vs disco local)"
sed -E 's#^([0-9]+) /(.*)$#\2 \1#' "$DEST/.lists/all.txt" | sort > /tmp/expected.lst
(cd "$ROOT" && find . \( -type f -o -type l \) -printf '%P %s\n') | sort > /tmp/local.lst
# Symlinks: tamanho local e remoto batem (tamanho do alvo em texto).
if diff -q /tmp/expected.lst /tmp/local.lst >/dev/null; then
  echo "   ok: $(wc -l < /tmp/local.lst) arquivos"
else
  echo "   DIVERGENCIA:"; diff /tmp/expected.lst /tmp/local.lst | head -20; fail=1
fi

echo "== sha256 de 300 originais do Immich"
(cd "$ROOT" && find home/htr/lab/immich/library/library -type f | shuf -n 300) | sort > /tmp/sample.lst
sed 's#^#/#' /tmp/sample.lst | ssh -o BatchMode=yes "$VM" "docker run --rm -i $MOUNTS alpine xargs -d '\n' sha256sum" \
  | sed 's#  /#  #' | sort -k2 > /tmp/remote.sha
(cd "$ROOT" && xargs -d '\n' sha256sum < /tmp/sample.lst) | sort -k2 > /tmp/local.sha
if [ -s /tmp/remote.sha ] && diff -q /tmp/remote.sha /tmp/local.sha >/dev/null; then echo "   ok"; else echo "   DIVERGENCIA"; fail=1; fi

echo "== dumps"
for f in "$ROOT"/home/htr/dumps/*.gz; do
  if gzip -t "$f" && zcat "$f" | tail -c 3000 | grep -qE 'dump complete|Dump completed'; then
    echo "   ok: $(basename "$f") $(du -h "$f" | cut -f1)"
  else
    echo "   FALHA: $f"; fail=1
  fi
done

exit $fail
