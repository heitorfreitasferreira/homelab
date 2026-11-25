# Hosts NixOS

Cada maquina e uma `nixosConfiguration` deste flake. O comin de cada host puxa o `main`
a cada minuto e aplica a config dele: o fluxo e editar, commitar e dar push.

```
nixos/
├── flake.nix                 nixos-26.05, disko, sops-nix, comin
├── modules/base.nix          comum: usuario htr, SSH so por chave, Tailscale, comin, sops, node-exporter
├── hosts/racknerd/           VPS (substitui o k3s)
├── secrets/<host>.sops.yaml  secrets do host, cifrados por inteiro com a chave age do repo
└── scripts/                  tailscale-prometheus e secret-gen
```

## racknerd

| Camada | Como roda |
|---|---|
| Postgres 17 + pgvector | nativo. Bancos `app` (Nextcloud) e `securo`. WAL e base diaria no R2 com wal-g (`s3://htr-backups/pg/racknerd`) |
| Apps | containers podman com as mesmas imagens fixadas do cluster, na rede `apps` (10.89.0.0/24, host em 10.89.0.1) |
| Entradas publicas | Caddy com Let's Encrypt: nuvem, audio, pedidos, securo e casa `.htrlab.duckdns.org` |
| Entradas da tailnet | Tailscale Services do proprio no: grafana, home, pihole, waha, prowlarr, transmission, metricas, securo-mcp |
| Metricas | VictoriaMetrics, vmalert, Alertmanager (Telegram), blackbox e Grafana nativos |
| Agentes | Hermes (gateway e dashboard), OpenCode e Anytype em systemd, binarios no home via nix-ld |
| Backup | restic diario no R2 (`htr-backups/restic/racknerd`), com dumps e snapshots SQLite antes |

Dados dos apps em `/srv/<app>`. Portas em 127.0.0.1: nextcloud 8081, securo 8000 (api),
8082 (web) e 8765 (mcp), waha 3001, homepage 3002, grafana 3000, vm 8428, audiobookshelf 13378,
readmeabook 3030, prowlarr 9696, transmission 9091, pihole web 8053.

## Operacao

- Build local sem Nix instalado: `docker run --rm -it -v nix-store:/nix -v $PWD:/work -w /work/nixos nixos/nix`
  e, dentro, `nix build .#nixosConfigurations.racknerd.config.system.build.toplevel`.
  O flake so enxerga arquivos rastreados pelo git (`git add`).
- Secret novo gerado: `nixos/scripts/secret-gen nixos/secrets/racknerd.sops.yaml <chave> [tamanho]`.
  Secret com valor dado: `sops nixos/secrets/racknerd.sops.yaml`.
- Deploy: push no `main`. O comin aplica em ate 1 min. Metricas dele em `127.0.0.1:4243`.

## Virada do racknerd (Debian 13 + k3s para NixOS)

Backup verificado em `~/backups/racknerd-20261124` (notebook). Recuperacao se algo der errado:
reinstalar o Debian 13 pelo painel da RackNerd e restaurar desse backup.

1. Antes: ensaio completo numa VM local com a config `racknerd` e os dados restaurados.
2. Mudar a policy da tailnet: tag `tag:server` dona dos Tailscale Services, regra de SSH para ela,
   servicos de `tag:k8s` para `tag:server`, apagar `svc:argocd`. O racknerd recebe `tag:server`.
3. Mover o chromium e o whisper do Hermes para containers no PC (hoje sao pods do k3s no WSL).
4. Tirar o Pi-hole do DNS global da tailnet (aparelhos ficam sem bloqueio, nao sem DNS).
5. Parar os apps, gerar os dumps finais e o rsync final da lista enxuta.
6. `nixos-anywhere` com kexec a partir do Debian, levando por `--extra-files`:
   `/var/lib/sops-nix/key.txt`, `/var/lib/tailscale` e as chaves de host do SSH.
7. Restaurar `/srv`, `/home/htr`, os bancos (pg_restore com `--no-owner` e `ALTER ... OWNER`),
   reinstalar Hermes (git no commit do manifesto), OpenCode, Anytype e os custom_apps do Nextcloud
   (`occ app:install memories previewgenerator`).
8. Conferir cada app, devolver o Pi-hole ao DNS global e rebaixar os audiobooks pelo transmission.

## Pendencias

- Rotacionar o que vazou no chat da migracao: token R2 de backups, chave do WAHA, senhas do
  Grafana, Pi-hole e admin do Nextcloud, URL do Healthchecks.
- `hermes-ops` e especifico do k8s (kubectl, Argo): reescrever para systemd e podman.
- Hosts `casa` (por ultimo, roda o Home Assistant) e `pc-wsl` (NixOS-WSL, worker sob demanda).
