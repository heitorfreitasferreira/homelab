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
   Os diretorios da pasta de extra-files viram os do disco novo com as mesmas permissoes:
   `etc`, `etc/ssh`, `var` e `var/lib` precisam ser 755. Com `etc/ssh` em 700 o sshd nao le
   `authorized_keys.d/htr` e ninguem entra por SSH (achado no ensaio).
   Opcoes usadas no ensaio: `--target-host htr@<ip> --post-kexec-ssh-port 22`.
7. Restaurar `/srv`, `/home/htr`, os bancos (pg_restore com `--no-owner` e `ALTER ... OWNER`),
   reinstalar Hermes (git no commit do manifesto), OpenCode, Anytype e os custom_apps do Nextcloud
   (`occ app:install memories previewgenerator`).
8. Conferir cada app, devolver o Pi-hole ao DNS global e rebaixar os audiobooks pelo transmission.

## Ensaio (2026-11-25)

Config `.#racknerd-ensaio` (`hosts/racknerd/ensaio.nix`): a do racknerd sem comin, wal-g, restic,
Alertmanager, cron do Nextcloud, gateway do Hermes, waha, worker do Securo e Tailscale Services.
VM no notebook (`~/vms/ensaio`): QEMU com BIOS, 6 GB, 5 vCPUs, MAC e IP do racknerd, Debian 13 cloud.
`instalar.sh` refaz do zero, `aplicar.sh` aplica mudancas, `rodar.sh` so liga.

Resultado com o backup de 2026-11-24:

- Debian -> kexec -> disko -> instalacao -> boot BIOS sem intervencao. O IP fixo sobreviveu ao kexec.
  A placa vira `ens3` no NixOS: a config casa pelo MAC, nao pelo nome.
- Chaves de host do SSH preservadas (mesma impressao digital do racknerd) e secrets decifrados.
- Bancos restaurados iguais aos dumps: Nextcloud 151 tabelas, Securo 67, readmeabook 28.
- Nextcloud 35.0.3 sobe com o config.php antigo, lista as pastas e baixa fotos do R2.
- Securo, audiobookshelf (2 usuarios, 2 progressos, 8 itens), readmeabook, prowlarr, transmission,
  Pi-hole, homepage e Grafana respondem. Os aliases mantem os nomes do cluster validos no readmeabook.
- Hermes reinstalado no commit de producao com as mesmas versoes de Node, npm e Python (nix-ld).
- Memoria com o ensaio todo no ar: 2,0 GB usados, swap vazio. Os servicos desligados no ensaio
  somam cerca de 1,5 GB na producao.

Achados corrigidos:

- `etc/ssh` em 700 na pasta de extra-files trancava o SSH de todos (passo 6 da virada).
- `hashedPassword = "!"` marca a conta como bloqueada. O htr usa `"*"`.
- Faltavam os diretorios cache, pgdata e redis do readmeabook (podman nao cria caminho de volume).
- O dump do readmeabook vai sem `--no-owner`, num container temporario com o app parado.
- Dune Messiah nao tem .torrent: ele e o Manifesto (ja organizado) entram no backup.
- O worker do Securo consome a fila restaurada do Redis e chama a Pluggy: no ensaio ficou desligado.

## Virada (2026-11-25, 01:45 a 02:40)

Feita com o runbook acima, a partir do backup de 2026-11-24 atualizado com os dumps finais.
Bancos conferidos contra o banco antigo congelado (0 diferencas), 7 livros rebaixados (299 arquivos),
os 8 nomes da tailnet com os mesmos IPs (servicos em tag:server), Let's Encrypt nos 5 dominios,
primeira base do wal-g e primeiro snapshot do restic no R2. O DNS da tailnet voltou ao Pi-hole.

Achados na virada: o pg_restore do Securo sai com codigo 1 pelos avisos do pgvector (script corrigido);
o tailscaled limpa a rota DNS de ts.net (timer); o Hermes passa PATH minimo aos MCPs (os wrappers em
~/.config/hermes/mcp e ~/.config/opencode/mcp declaram o proprio PATH); containers subiram durante a
restauracao e o transmission precisou de restart para ler a config restaurada.

## Pendencias

- Rotacionar o que vazou no chat da migracao: token R2 de backups, chave do WAHA, senhas do
  Grafana, Pi-hole e admin do Nextcloud, URL do Healthchecks.
- Home Assistant bane os acessos por casa.tail76c1c6.ts.net (403, ja antes da virada): revisar ip_bans no casa.
- Chromium e whisper do Hermes: containers no PC (eram pods do k3s no WSL).
- Healthchecks: check novo alertmanager-watchdog criado, falta trocar a URL (nixos/scripts/rotacionar healthchecks).
- Remover da tailnet os nos k8s-operator-racknerd e racknerd-ingress-0, o svc:argocd e o vcluster.
- Atualizar o `DECISIONS.md` para a arquitetura NixOS (decisao 1 e as de k3s).
- Hosts `casa` (por ultimo, roda o Home Assistant) e `pc-wsl` (NixOS-WSL, worker sob demanda).
