# Manga

A biblioteca vive no celular, no Mihon. Não há serviço no servidor: o
Suwayomi saiu da VPS e o `svc:manga` saiu da tailnet.

| O que | Onde |
| ----- | ---- |
| Acervo | `/storage/emulated/0/Mihon/local/<Série>/` |
| Downloads do Mihon | `/storage/emulated/0/Mihon/downloads/<Fonte>/<Série>/` |
| Backup da biblioteca | `/storage/emulated/0/Mihon/autobackup/` (12 h) |

Estado em 25/11/2026, no M53: Storage location em `/storage/emulated/0/Mihon`,
**Salvar como arquivo CBZ** ligado e One Piece em `local` com um capítulo.

## Como a biblioteca cresce

1. Baixar pelo Mihon normalmente. Com CBZ ligado, cada capítulo vira um
   arquivo em `downloads/<Fonte>/<Série>/`.
2. Para o acervo, mover a pasta da série de `downloads/<Fonte>/` para `local/`.
   Isso corta o vínculo com a extensão: `local` não usa rede nem fonte.
3. Browse > Fontes > Fonte local, puxar para atualizar. Série nova aparece.
4. `cover.jpg` na pasta da série vira a capa, e `.nomedia` em `local/` mantém as
   páginas fora da galeria.

`downloads` e `local` são bibliotecas diferentes no Mihon. A primeira lê
offline enquanto o arquivo existir, mas continua presa à extensão. A segunda é
o acervo.

## Espaço

Um capítulo em CBZ fica em 20 a 30 MB. O aparelho tinha 10 GB livres, o que dá
uns 300 a 500 capítulos. `local/` está no armazenamento compartilhado, então
sobrevive a desinstalar o Mihon, mas não a um reset ou perda do aparelho.

## Quando a fonte cair

Capítulo que já está em `local` abre para sempre, sem rede. Crescer a
biblioteca depende da fonte existir, e isso vale para qualquer solução.
