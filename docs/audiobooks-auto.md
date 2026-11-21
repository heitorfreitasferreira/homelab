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

O Ingress de Prowlarr e Transmission sobe pelo operator do Tailscale, mas o servico
`svc:prowlarr` e `svc:transmission` nasce sem aprovacao. Aprovar o proxy em
`https://login.tailscale.com/admin/services` uma vez. Ate la o RMAB fala com os dois
pela rede do cluster, e so os nomes `*.tail76c1c6.ts.net` ficam sem resposta.

Discos novos: config do Prowlarr 1 GiB, config e downloads do Transmission 1 + 10 GiB,
ReadMeABook 1 GiB de config, 1 GiB de cache, 2 GiB de pgdata e 256 MiB de Redis.

## 1. Prowlarr e MyAnonamouse

1. Abrir o Prowlarr, criar usuario e senha.
2. Settings > Indexers > Add Indexer > MyAnonamouse.
3. No campo `mam_id`, colar o valor do cookie `mam_id` da sessao logada no site.
   Trocar esse cookie e trocar a senha: vale como credencial.
4. Testar e salvar. A API key do Prowlarr fica em Settings > General.

Sem VPN no VPS. O MAM e tracker privado e nao exige, mas o IP do racknerd fica visivel
para os peers.

## 2. Transmission

A senha do RPC esta em `apps/audio-auto/secrets.sops.yaml`, chave `TRANSMISSION_PASS`.
Para ler:

```sh
mise exec -- sops --decrypt apps/audio-auto/secrets.sops.yaml
```

Usuario `admin`. A porta 51413 nao esta publicada na internet: o Transmission so faz
conexoes de saida, o que derruba a taxa de peers e o ratio. Abrir a porta exige regra
no firewall da VPS e TCP no Traefik, e fica para quando o ratio importar.

## 3. ReadMeABook

O wizard do primeiro acesso nao tem senha: entre nele logo depois do sync.

1. Backend: Audiobookshelf.
2. API token: criar no AudioBookshelf em Settings > Users > o usuario > API Token.
   URL do servidor: `http://audiobookshelf.audiobookshelf.svc`.
3. Biblioteca: escolher a de audiobooks.
4. Prowlarr: `http://prowlarr:9696` e a API key do passo 1. Marcar o MyAnonamouse.
5. Download client: Transmission, host `transmission`, porta `9091`, usuario `admin`,
   senha do passo 2, pasta de download `/downloads`.
6. Paths: downloads `/downloads`, media `/media/audiobooks` (o default do wizard).
7. Terminar. O RMAB varre a biblioteca, dispara a primeira busca e liga os jobs.

O ReadMeABook copia o download para a biblioteca e apaga o torrent depois de conferir a
copia. Os arquivos ficam em `Autor/Titulo ASIN/`, que e o layout que o AudioBookshelf
espera.

## Backup

Dois volumes andam juntos: `readmeabook-pgdata` (Postgres do RMAB) e
`readmeabook-config` (`.secrets` com a senha do Postgres e o JWT). Restaurar um sem o
outro quebra o RMAB. Ainda nao ha backup no R2.

## RAM

O stack pede cerca de 1 GiB (ReadMeABook 384 Mi de request, Prowlarr 128 Mi,
Transmission 64 Mi) num no com 640 MB livres. O kernel vai usar swap. Se apertar, o
primeiro candidato a sair e o ReadMeABook, que e o mais pesado.
