# Audiobooks automaticos

Prowlarr busca, o ReadMeABook decide e pede, o Transmission baixa, o AudioBookshelf toca.

| Servico       | Onde                                              | Namespace       |
| ------------- | ------------------------------------------------- | --------------- |
| ReadMeABook   | `https://pedidos.htrlab.duckdns.org`              | audiobookshelf  |
| Prowlarr      | `https://prowlarr.tail76c1c6.ts.net`              | audiobookshelf  |
| Transmission  | `https://transmission.tail76c1c6.ts.net`          | audiobookshelf  |

Tudo em `apps/audio-auto`, no mesmo namespace do AudioBookshelf porque o ReadMeABook
monta o PVC `audiobookshelf-audiobooks` em `/media/audiobooks`. E o mesmo diretorio que
o AudioBookshelf ve como `/audiobooks`.

## Estado em 21/11/2026

- Prowlarr 3.0.2 com o indexador publico **Knaben** e um cliente de download
  **Transmission** configurado. O MyAnonamouse ainda nao entrou: falta o cookie `mam_id`.
- Transmission 4.1.4 sem senha no RPC (so tailnet e rede do cluster) e com a biblioteca
  montada em `/audiobooks`. O diretorio padrao de download e `/downloads`.
- Os 5 livros de Percy Jackson e os Olimpianos estao na biblioteca do AudioBookshelf,
  completos e com capa, autor, narrador e capitulos. Foram baixados pelo Knaben e
  gravados direto em `/audiobooks` (`TRANSMISSION_DOWNLOAD_DIR` temporario).
- O ReadMeABook esta de pe, mas o wizard nao foi concluido (`setupComplete: false`).
- O Prowlarr abre um modal de "Authentication Required" e nao deixa usar a interface
  enquanto nao houver usuario e senha. A API funciona com a chave de
  `/initialize.json`, que e o caminho usado para os indexadores.

## Prowlarr e indexadores

1. Abrir o Prowlarr e definir usuario e senha no modal (o campo nao aceita "None").
2. Settings > Indexers > Add Indexer > MyAnonamouse, colar o cookie `mam_id` da sessao
   logada no site. Vale como credencial: trocar o cookie e trocar a senha.
3. A API key fica em Settings > General.

## Transmission

Sem senha por decisao desta rodada: o Ingress e so da tailnet e o RPC nao responde fora
do cluster. Para voltar a exigir senha, use `USER` e `PASS` no Deployment e um Secret
SOPS com a chave `TRANSMISSION_PASS`.

A porta 51413 nao esta publicada na internet: so conexoes de saida, ratio pior. Abrir
exige regra no firewall da VPS e TCP no Traefik.

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

## Backup

Dois volumes andam juntos: `readmeabook-pgdata` (Postgres do RMAB) e
`readmeabook-config` (`.secrets` com a senha do Postgres e o JWT). Restaurar um sem o
outro quebra o RMAB. Ainda nao ha backup no R2.

## RAM

O stack pede cerca de 576 Mi de requests num no com cerca de 700 MB livres. O kernel usa
swap. Se apertar, o primeiro candidato a sair e o ReadMeABook.
