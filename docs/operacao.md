# Operacao do homelab

Rotina pelo Hermes na racknerd. Mudanca pesada de infraestrutura pelo OpenCode no
notebook. O racknerd e NixOS com GitOps: o repo e a fonte de verdade, o comin
aplica.

## Fonte de verdade

- `main` de `github.com/heitorfreitasferreira/homelab`.
- `DECISIONS.md` explica o porque de cada escolha. Leia antes de propor mudanca.
- `nixos/` declara o racknerd, um arquivo por assunto em `nixos/hosts/racknerd`.
- `nixos/README.md` tem o fluxo, a operacao e o runbook da virada.
- O dado vivo vence o repo na hora de diagnosticar. O repo vence na hora de mudar.

Nunca edite o host a mao para "resolver rapido". Se precisar, registre a
excecao, reconcilie no repo e deixe o comin voltar ao estado declarado.

## Nos

- `racknerd`: VPS NixOS 26.05, sempre ligada. Roda os apps em containers podman,
  o Postgres nativo, o Caddy, a Tailscale, o monitoring, o Hermes, o OpenCode e o
  Anytype. Nada e exposto fora da tailnet, exceto as cinco entradas do Caddy.
- `casa`: notebook em casa, Debian 13, Podman Quadlet, Home Assistant e Matter
  Hub. Provisionado por `ansible/casa.yml`.
- `pc-heito-wsl`: computacao sob demanda, nao e servidor.

## Fluxo de mudanca

1. Edite o repo.
2. `git add`, `git commit`, `git push`.
3. O comin puxa o `main` em ate 1 min, avalia a config e aplica com
   `nixos-rebuild switch`. Ele guarda geracao, entao o rollback e barato.
4. Confira: `systemctl status comin`, `curl -s 127.0.0.1:4243/metrics | grep
   comin_deployment_info` e o servico afetado.
5. Rollback: `git revert` e push, ou `nixos-rebuild --rollback` no host.

## Comandos

```bash
systemctl status comin                     # estado do GitOps
journalctl -u comin -n 50 --no-pager       # o que ele fez
sudo nixos-rebuild switch                  # aplica a config local (sem push)
sudo nixos-rebuild --rollback              # volta a geracao anterior
sudo podman ps -a --format '{{.Names}}\t{{.Status}}'
systemctl --failed
free -m; uptime; df -h /
```

Servicos por app: `podman-<app>.service` (nextcloud, securo-backend,
securo-worker, securo-frontend, securo-mcp, waha, pihole, audiobookshelf,
readmeabook, prowlarr, transmission, homepage). Banco: `postgresql.service`.
Entradas: `caddy.service`. Metricas: `victoriametrics.service`,
`vmalert-homelab.service`, `alertmanager.service`, `grafana.service`.
Agentes: `hermes-gateway.service`, `hermes-dashboard.service`,
`opencode.service`, `anytype.service` (de usuario).

## Backup

Tudo cai em `htr-backups` no R2.

- Postgres: WAL continuo e base diaria as 04:00 pelo `wal-g-backup.timer`
  (`s3://htr-backups/pg/racknerd`, retencao de 30 bases). Os bancos `app`
  (Nextcloud) e `securo` vivem na mesma instancia.
- `pg_dump` dos dois bancos as 03:00 pelo `postgresqlBackup`, em
  `/var/backup/postgresql`.
- Restic as 03:30 (`restic-backups-r2.timer`): `/srv`, `/home/htr`, o estado da
  Tailscale e `/var/backup`. Antes da copia ele dumpa o readmeabook e fotografa
  os SQLite que ficam abertos (Hermes, audiobookshelf, prowlarr, Pi-hole).
- Restaurar: o `restaurar-racknerd` e o script da virada, da epoca do k3s. Para
  os backups atuais, siga "Restaurar do R2" abaixo.

### Restaurar do R2

Depois de instalar o NixOS com a chave age (`nixos/README.md`), como root:

```bash
systemctl stop restic-backups-r2.timer wal-g-backup.timer
systemctl stop 'podman-*.service'
restic-r2 restore latest --target /

systemctl start postgresql
sudo -u postgres psql -d postgres -c 'DROP DATABASE IF EXISTS app;'
sudo -u postgres psql -d postgres -c 'DROP DATABASE IF EXISTS securo;'
sudo -u postgres zstd -dc /var/backup/postgresql/app.sql.zst | sudo -u postgres psql -v ON_ERROR_STOP=1 -d postgres
sudo -u postgres zstd -dc /var/backup/postgresql/securo.sql.zst | sudo -u postgres psql -v ON_ERROR_STOP=1 -d postgres
```

O `postgresqlBackup` guarda so o dia (`app.sql.zst`) e o anterior
(`app.prev.sql.zst`). O restic ja inclui os dumps. Para point-in-time, o wal-g
tem a base diaria e o WAL em `s3://htr-backups/pg/racknerd`.

O readmeabook tem Postgres proprio dentro do container e um dump em custom
format. Deixe o container criar o pgdata uma vez, pare e rode o restore:

```bash
systemctl start podman-readmeabook
# espere o banco responder e pare
systemctl stop podman-readmeabook
IMG=$(podman inspect readmeabook --format '{{.ImageName}}')
podman run --rm -i -v /srv/audiobooks/readmeabook/pgdata:/var/lib/postgresql/data --entrypoint sh "$IMG" -c '
  B=/usr/lib/postgresql/16/bin
  su postgres -c "$B/pg_ctl -D /var/lib/postgresql/data -w -o \"-c listen_addresses=\" start" >/dev/null
  cat > /tmp/d.dump
  su postgres -c "$B/pg_restore --clean --if-exists -d readmeabook /tmp/d.dump"
  su postgres -c "$B/pg_ctl -D /var/lib/postgresql/data -w stop" >/dev/null' < /var/backup/readmeabook/readmeabook.dump
```

Por fim, suba os containers e os timers, reinstale Hermes, OpenCode e Anytype
como no `nixos/README.md`, e confira cada app.

```bash
systemctl start 'podman-*.service'
systemctl start restic-backups-r2.timer wal-g-backup.timer
```

## Secrets

- `nixos/secrets/racknerd.sops.yaml`, decifrado no boot pelo sops-nix com a
  chave em `/var/lib/sops-nix/key.txt`.
- Novo secret gerado: `nixos/scripts/secret-gen nixos/secrets/racknerd.sops.yaml <chave>`.
- Rotacao: `nixos/scripts/rotacionar r2|healthchecks`.

## Health checks

- Publicos: `nuvem`, `audio`, `pedidos`, `securo` e `casa` em
  `*.htrlab.duckdns.org`.
- Tailnet: `grafana`, `home`, `pihole`, `waha`, `prowlarr`, `transmission`,
  `metricas`, `securo-mcp` e o proprio `racknerd`.
- Alerta: `AlvoFora`, `ServicoFora`, `MemoriaBaixa`, `DiscoQuaseCheio`,
  `BackupAtrasado`, `SiteFora` em `https://grafana.tail76c1c6.ts.net`.

## Monitoring

- VictoriaMetrics em `127.0.0.1:8428`, consulta em `metricas.tail76c1c6.ts.net/vmui`.
- vmalert avalia as regras de `nixos/hosts/racknerd/alert-rules.json`.
- Alertmanager manda para o Telegram e para o Healthchecks.
- Grafana provisiona os paineis de `nixos/hosts/racknerd/dashboards` e o Node
  Exporter Full.

## Casa

- `ansible-playbook casa.yml` a partir do repo, onde o Ansible esta instalado.
  `-e ansible_host=casa.local` quando estiver na LAN de casa.
- Home Assistant em `casa.htrlab.duckdns.org` e o interno em
  `http://192.168.100.207:8123`.
