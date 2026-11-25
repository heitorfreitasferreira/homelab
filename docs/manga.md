# Manga

Suwayomi (o Tachidesk) faz o papel do readmeabook, do transmission e do
Audiobookshelf juntos: busca na fonte, baixa o capítulo em CBZ, guarda a
biblioteca e serve as páginas. O Mihon do celular lê pelo plugin Suwayomi.

| Servico | Onde |
| ------- | ---- |
| Suwayomi | `https://manga.tail76c1c6.ts.net` |
| Dados | `/srv/manga/data` (container `suwayomi`, porta 127.0.0.1:4567) |

Só tailnet, sem senha, como o transmission. Fora da tailnet não responde.

O serviço `svc:manga` precisa existir antes: Services > Add service, nome
`manga`, porta `tcp:443`. O `tailscale serve` só vira host depois disso. O
autoApprover do policy libera o racknerd, mas não cria o serviço.

## Primeiro acesso

1. Abrir o endereço acima e conferir se a loja Keiyoushi apareceu em
   Settings > Browse. Se não apareceu, adicionar
   `https://github.com/keiyoushi/extensions/raw/repo/index.pb`.
2. Browse > Extensions: instalar **MangaDex** e o que mais quiser
   (Comick, WeebCentral). Filtrar por idioma antes de instalar.
3. Nas opções da extensão MangaDex, entrar com conta do MangaDex. Sem conta o
   site libera 10 capítulos por dia desde maio de 2026.
4. Filtrar a busca por `pt-br` no canto da tela.
5. Buscar, adicionar à biblioteca e marcar os capítulos para baixar. O timer do
   Suwayomi busca capítulo novo das séries seguidas a cada algumas horas.

## Mihon

1. Browse > Extensions > Extension stores > Add e colar
   `https://raw.githubusercontent.com/suwayomi/tachiyomi-extension/repo/index.min.json`.
2. Instalar a extensão **Suwayomi** e, nas configurações dela, pôr a URL do
   servidor. Usuário e senha em branco.
3. Settings > Tracking > Suwayomi, mesma URL. É o tracker que leva o capítulo
   lido do Mihon para o servidor e traz o estado de volta ao abrir a ficha da
   série.

O progresso vive no Mihon e sincroniza com o servidor pelo tracker. Entre dois
celulares, abrir a ficha da série força a atualização.

## Disco e backup

Os CBZ ficam em `/srv/manga/data/downloads` e não entram no restic, como os
audiobooks. O banco e o `server.conf` do app entram. Com 66 GB livres cabem
umas 250 a 400 volumes de 150 a 250 MB. Volume novo vem de série nova.

## Quando o MangaDex recusar

O MangaDex limita por IP (5 req/s) e alguns IPs de datacenter nunca passam. Teste
na racknerd:

```sh
curl -s -o /dev/null -w '%{http_code}\n' https://api.mangadex.org/ping
```

`200` está liberado. `403` quer dizer IP barrado: trocar para outra fonte na
lista de extensões (Comick, WeebCentral) ou baixar pelo notebook, que sai pelo
IP residencial.
