# Inventario da VM atual (2026-11-12)

Retrato do estado antes da migracao. Dado vivo: `ssh htr@23.254.208.229` e `docker ps`.

## Acesso

- `ssh htr@23.254.208.229`, autenticacao por chave. Sem alias no `~/.ssh/config`.
- Usuario `htr` (uid 1000), grupos `sudo` e `docker`. `sudo` pede senha.
- Painel RackNerd: SolusVM (`ctrl.racknerd.com`, vserverid 497219). Sem API key gerada.

## Host

- Debian 13, 5 vCPU, 5.8 GiB RAM, swap 3 GiB, disco 96 GB.
- Disco em 97% (92 GB usados, 3.4 GB livres).
- Sem virtualizacao aninhada (`vmx/svm` = 0).
- Firewall: `ufw` e `nftables` inativos. Todas as portas publicadas pelo Docker ficam abertas na internet.

## Servicos (Docker Compose em `~/lab/<servico>/compose.yml`)

| Servico | Portas publicas | Dados | Observacao |
| --- | --- | --- | --- |
| immich (server, ML, postgres 14 + vectorchord 0.4.3, valkey) | 3001 HTTP | `~/lab/immich/library` 71 GB, `~/lab/immich/postgres` 380 MB | 10175 assets (7628 fotos, 2547 videos), 3 usuarios |
| pihole | 53 tcp/udp, 3002 HTTP | `~/lab/pi-hole/etc-pihole` 1.2 GB | resolver aberto para a internet. Senha do admin em claro no compose |
| wireguard (linuxserver) | 51820 udp | `~/lab/wireguard/config` | 1 peer, DNS do peer aponta para o pihole |
| firefly iii (core, importer, mariadb, cron) | 3003 e 81 HTTP | volume `firefly_firefly_iii_db` 178 MB | |
| n8n + traefik | 80, 443 | volume `n8n_n8n_data` 754 KB | `DOMAIN_NAME` vazio no `.env`: rota do Traefik nao casa com nada |
| heimdall | 3000, 3443 | bind `/path/to/heimdall/config` | caminho placeholder do exemplo |

RAM em repouso (`docker stats`, 2026-11-12): total ~2.8 GB. Immich ~1.2 GB (server 547 MB, ML 386 MB, postgres 227 MB, valkey 32 MB), n8n 351 MB, pihole 351 MB, firefly ~415 MB, heimdall 142 MB, traefik 134 MB, wireguard 97 MB.

Cron do `htr`: `~/scripts/notificar_do_bbb.py` as 21h.

## Composicao do Immich (71 GB)

| Pasta | Tamanho | Precisa de backup |
| --- | --- | --- |
| `library/library` (originais) | 53 GB | sim |
| `library/upload` | 54 MB | sim |
| `library/backups` (dumps do banco gerados pelo Immich) | 941 MB | sim |
| `library/encoded-video` | 16 GB | nao, regeneravel |
| `library/thumbs` | 2.1 GB | nao, regeneravel |
| `postgres` | 380 MB | sim, via dump |

## Projeto TCC

- `~/tcc`, remote `git@github.com:heitorfreitasferreira/tcc.git`, ultimo commit `6563b56`.
- 15 arquivos nao versionados em `src/data` (grafos `16a/b/c` e resultados bruteforce). `src/data` tem 138 MB.

## Lixo recuperavel

- Volumes orfaos do Nextcloud: `nextcloud_nextcloud` 2.6 GB, `nextcloud_db` 171 MB.
- Imagens Docker: 11.9 GB no total.

## Riscos atuais

1. Nenhum backup off-site. Os 53 GB de originais do Immich existem em uma copia so.
2. Com 3.4 GB livres, o proximo lote de upload do Immich enche o disco.
3. Pihole responde DNS para qualquer IP da internet (pode ser usado em ataque de amplificacao e gerar abuse na RackNerd).
4. Immich, Firefly e Pihole admin expostos em HTTP sem TLS.
