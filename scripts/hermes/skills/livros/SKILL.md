---
name: livros
description: Busca, baixa e acompanha audiobooks pelo Prowlarr e Transmission, e sugere livros a partir da biblioteca do AudioBookshelf. Use quando o pedido for baixar, procurar, listar ou sugerir audiobook.
---

# Livros

Automação do stack de audiobooks do homelab. O cliente é o `hermes-books`
(`/usr/local/bin/hermes-books`), que fala com o Prowlarr, o Transmission e o
AudioBookshelf pela rede `apps` do podman, pelos nomes de servico (prowlarr,
transmission, audiobookshelf). Nunca chame `curl` ou a API direto: use o cliente.

## Comandos

```bash
hermes-books search "<titulo ou autor>"   # lista até 10 resultados com tamanho e seeders
hermes-books get <numero>                 # baixa o resultado da última lista
hermes-books get --query "<titulo>" --best # busca e baixa o de mais seeders
hermes-books status                       # progresso dos torrents
hermes-books library                      # títulos e autores da biblioteca
hermes-books library --json               # o mesmo, para você raciocinar
```

## Baixar

1. Rode `search` com o que o usuário pediu.
2. Mostre no máximo 3 opções, com tamanho e seeders. Diga quando for pack de
   vários livros (tamanho grande, título com "collection", "series").
3. Se o usuário já disse "baixa", pegue a melhor opção individual com
   `get <numero>` ou `get --query ... --best` e confirme o que foi enviado.
4. Se o pedido for vago, pergunte qual das opções.
5. Depois de enviar, rode `status` e informe o progresso. Não diga que baixou
   antes de o torrent chegar a 100%.
6. Ao completar, o AudioBookshelf indexa sozinho. Se em alguns minutos o livro
   não aparecer na biblioteca, avise para rodar o scan em
   `https://audio.htrlab.duckdns.org/audiobookshelf`.

Nunca invente resultado, seeder ou conclusão. Se o `search` não achar nada,
diga o que foi tentado e sugira outro termo (nome do autor, título em inglês).

## Sugerir

Quando o usuário pedir sugestão, ou na rotina semanal:

1. Rode `hermes-books library --json` para ver títulos, autores e séries.
2. Proponha 5 livros que não estejam na lista, priorizando: continuação de
   série que ele já tem, mesmo autor, mesmo gênero e clássicos do gênero.
3. Uma linha de justificativa por sugestão, ligada ao que ele já tem.
4. Opcional: rode `search` para cada sugestão e diga só o que o resultado
   mostra (achou ou não, tamanho, seeders). Não prometa disponibilidade sem
   essa checagem.
5. Ofereça baixar as escolhidas.

## Rotina semanal (opcional)

O usuário cria um job no dashboard do Hermes (Cron) com este texto, domingo às
19:30, entrega no Telegram:

> Leia a skill livros. Rode `hermes-books library --json`, escolha 5 livros que
> não estão na biblioteca, priorizando séries em andamento e o mesmo autor.
> Confira a disponibilidade com `hermes-books search` e mande a lista curta com
> uma linha de justificativa cada e o tamanho. Não baixe nada sem resposta.

## Regras

- Pack de 7 GB com vários livros só se o usuário pedir o pacote.
- Não imprima chaves, tokens nem caminhos de segredo.
- Se `hermes-books` falhar por falta de `ABS_TOKEN`, a sugestão continua
  possível pelo que o usuário contou, mas diga que a lista da biblioteca
  depende do token em `~/.hermes/books.env`.
- O Prowlarr tem login local (`admin`). A API key e a senha ficam em
  `~/.hermes/books.env` (`PROWLARR_API_KEY`, `PROWLARR_USER`, `PROWLARR_PASS`).
  Se a busca falhar com 401, a chave foi trocada: peça a nova em Settings > General.
- Nunca mostre a senha do Prowlarr; se o usuario pedir, diga que esta no
  `books.env` da racknerd.
