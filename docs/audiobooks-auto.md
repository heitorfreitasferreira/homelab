# Audiobooks automaticos

Prowlarr busca, o ReadMeABook decide e pede, o Transmission baixa, o AudioBookshelf toca.

| Servico       | Onde                                              |
| ------------- | ------------------------------------------------- |
| ReadMeABook   | `https://pedidos.htrlab.duckdns.org`              |
| Prowlarr      | `https://prowlarr.tail76c1c6.ts.net`              |
| Transmission  | `https://transmission.tail76c1c6.ts.net`          |

Tudo em containers podman na rede `apps` do racknerd, com as portas em
127.0.0.1: ReadMeABook 3030, Prowlarr 9696, Transmission 9091 e AudioBookshelf
13378. O ReadMeABook monta `/srv/audiobooks/library` em `/media/audiobooks`, o
mesmo diretorio que o AudioBookshelf ve como `/audiobooks`.

## Estado em 21/11/2026

- Prowlarr 3.0.2 com o indexador publico **Knaben** e um cliente de download
  **Transmission** configurado. O MyAnonamouse ainda nao entrou: falta o cookie `mam_id`.
- Transmission 4.1.4 sem senha no RPC (so a tailnet e 127.0.0.1) e com a biblioteca
  montada em `/audiobooks`. O diretorio padrao de download e `/downloads`.
- Os 5 livros de Percy Jackson e os Olimpianos estao na biblioteca do AudioBookshelf,
  completos e com capa, autor, narrador e capitulos. Foram baixados pelo Knaben e
  gravados direto em `/audiobooks` (`TRANSMISSION_DOWNLOAD_DIR` temporario).
- O ReadMeABook esta de pe, mas o wizard nao foi concluido (`setupComplete: false`).
- O Prowlarr tem login local (`admin`), porque a versao nova exige autenticacao para
  ouvir em rede. A senha e a API key ficam em `~/.hermes/books.env` na racknerd
  (`PROWLARR_USER`, `PROWLARR_PASS`, `PROWLARR_API_KEY`), modo 600.

## Prowlarr e indexadores

1. Entrar em `https://prowlarr.tail76c1c6.ts.net` com `admin` e a senha de
   `~/.hermes/books.env` (`PROWLARR_PASS`).
2. Settings > Indexers > Add Indexer > MyAnonamouse, colar o cookie `mam_id` da sessao
   logada no site. Vale como credencial: trocar o cookie e trocar a senha.
3. A API key fica em Settings > General e ja esta no `books.env` (`PROWLARR_API_KEY`).
   Se for trocada, atualize o arquivo.

## Transmission

Sem senha por decisao desta rodada: a entrada e so da tailnet e o RPC nao responde fora
do host. Para voltar a exigir senha, use `USER` e `PASS` no Deployment e um Secret
SOPS com a chave `TRANSMISSION_PASS`.

A porta 51413 nao esta publicada na internet: so conexoes de saida, ratio pior. Abrir
exige regra no firewall da VPS e publicacao no container.

## ReadMeABook

O wizard do primeiro acesso nao tem senha: entre nele logo depois do sync.

1. Backend: Audiobookshelf.
2. API token: criar no AudioBookshelf em Settings > API Keys, atuando em nome de `root`.
   URL do servidor: `http://audiobookshelf.audiobookshelf.svc`.
3. Biblioteca: `Audiobooks` (id `3e1d2334-575b-4564-9e4d-36cec204ed74`), pasta `/audiobooks`.
4. Prowlarr: `http://prowlarr:9696` e a API key do Settings > General.
5. Download client: Transmission, `http://transmission:9091`, urlBase `/transmission/`,
   sem usuario e sem senha, pasta `/downloads`.
6. Paths: downloads `/downloads`, media `/media/audiobooks`.
7. Terminar.

Os 5 livros ja estao na biblioteca. O RMAB marca "In Your Library" e nao vai pedir de novo.

## Skill do Hermes

O Hermes pede e baixa livros com a skill `livros` e o cliente `hermes-books`,
que fala com Prowlarr (127.0.0.1:9696), Transmission (127.0.0.1:9091) e
AudioBookshelf (127.0.0.1:13378). Roda na racknerd, usuario `htr`.

O cliente vem do `nixos/hosts/racknerd/agents.nix`. So o env e a skill sao
criados a mao:

```sh
install -d ~/.hermes/skills/livros
install -m 644 scripts/hermes/skills/livros/SKILL.md ~/.hermes/skills/livros/SKILL.md
install -m 600 /dev/null ~/.hermes/books.env
```

Em `~/.hermes/books.env`:

```sh
ABS_TOKEN=...            # AudioBookshelf > Settings > API Keys, para a biblioteca
# ABS_LIBRARY_ID=3e1d2334-575b-4564-9e4d-36cec204ed74  # opcional, este e o default
# PROWLARR_API_KEY=...   # so depois que o Prowlarr tiver login
# PROWLARR_URL=http://127.0.0.1:9696      # opcional
# TRANSMISSION_URL=http://127.0.0.1:9091  # opcional
# ABS_URL=http://127.0.0.1:13378          # opcional
```

Sem `PROWLARR_API_KEY` o cliente usa a chave de `/initialize.json`, que existe enquanto
o Prowlarr nao tem login. Sem `ABS_TOKEN`, buscar e baixar funcionam e `library` falha
com a instrucao.

Teste:

```sh
hermes-books search "percy jackson"
hermes-books status
hermes-books library --limit 5
```

Para a sugestao semanal, criar um job no dashboard do Hermes (Cron), domingo 19:30,
entrega no Telegram, com o texto que esta na skill (`scripts/hermes/skills/livros/SKILL.md`).

## Backup

Dois volumes andam juntos: `readmeabook-pgdata` (Postgres do RMAB) e
`readmeabook-config` (`.secrets` com a senha do Postgres e o JWT). Restaurar um sem o
outro quebra o RMAB. O restic diario leva o config e o dump do banco, feito antes da
copia. O pgdata fica fora.

## RAM

O stack pede cerca de 576 Mi de requests num no com cerca de 700 MB livres. O kernel usa
swap. Se apertar, o primeiro candidato a sair e o ReadMeABook.
