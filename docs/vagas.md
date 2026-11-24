# Vagas e candidaturas

Fluxo do Hermes para buscar vagas, medir aderencia, preparar candidatura e
alimentar posts de LinkedIn. O notebook e a fonte de verdade do curriculo e do
workspace. A racknerd recebe a ultima copia no pacote diario das 18:20.

## Dados na racknerd

- `~/.hermes/vagas/curriculo-base.md` e `.en.md`
- `~/.hermes/vagas/regras-curriculo.md`
- `~/.hermes/vagas/ESTADO.md`
- `~/.hermes/vagas/triagem.md`
- `~/.hermes/vagas/lista.md`
- `~/.hermes/vagas/descricoes/<slug>.md`
- `~/.hermes/vagas/buscas/latest.md`
- `~/.hermes/vagas/aplicacoes.md`
- `~/.hermes/linkedin/latest.md`

O pacote e gerado por `scripts/hermes/hermes-activity-digest` no notebook. Se a
linha `Gerado em` do `latest.md` tiver mais de dois dias, o notebook esta
desligado. Use o ultimo pacote e diga que esta desatualizado.

## Buscar

```bash
vagas-buscar "platform engineer" --location Brazil --limit 10
vagas-buscar "sre" --sources remotive,remoteok,wwr --limit 10
vagas-buscar "devops" --json --out ~/.hermes/vagas/buscas/2026-11-19.json
```

Fontes: LinkedIn guest, Remotive, RemoteOK, We Work Remotely e, na racknerd, os
grupos de vagas do WhatsApp. Da racknerd o LinkedIn pode falhar por rate limit.
Use as outras fontes e a ultima busca que o notebook sincronizou. A linha
`Fontes:` da saida diz o que rodou.

Com o PC ligado, o LinkedIn sai pelo navegador do WSL:

```bash
vagas-buscar "platform engineer" --location Brazil --limit 10 \
  --sources linkedin-browser,remotive,remoteok,wwr
```

## Fontes com chave

Adzuna, Jooble e SerpApi Google Jobs leem `~/.hermes/vagas/api.env`, modo `600`:

```bash
ADZUNA_APP_ID=...
ADZUNA_APP_KEY=...
JOOBLE_KEY=...
SERPAPI_KEY=...
```

Use `--sources adzuna,jooble,serpapi`. O SerpApi Google Jobs e o que mais se
aproxima dos resultados do LinkedIn. Nenhuma dessas chaves e do LinkedIn.

## Grupos do WhatsApp

A fonte `whatsapp` le os grupos de vagas do numero principal pelo WAHA, com uma
chave de sessao somente leitura. Ela entra no padrao quando `WAHA_READ_KEY`
existe no `api.env`, o que so acontece na racknerd. No notebook ela fica fora e
o digest das 18:20 nao muda.

```bash
WAHA_READ_KEY=...                                  # chave da sessao, so read
WAHA_SESSION=heitor                                # padrao
WAHA_URL=https://waha.tail76c1c6.ts.net            # padrao
WAHA_JOB_CHATS=Dominando Cloud;UberHub Comunidade  # padrao, separado por ;
```

Cada item de `WAHA_JOB_CHATS` e um trecho do nome do chat, sem caixa e sem
acento, ou um id `...@g.us`. O script le ate 1000 mensagens por chat dentro de
`--days`. Fica so o post com cargo nas tres primeiras linhas e com link ou
e-mail, filtrado pelos termos da busca com sinonimos (sre, devops, plataforma,
cloud, kubernetes, infra, dados). Cada resultado traz grupo e trecho.

```bash
vagas-buscar "devops" --sources whatsapp --days 7 --limit 20
```

Para criar a chave na racknerd sem ela passar pela tela:

```bash
( umask 077
  ADMIN=$(sudo kubectl -n waha get secret waha-secrets -o jsonpath='{.data.WAHA_API_KEY}' | base64 -d)
  curl -fsS https://waha.tail76c1c6.ts.net/api/keys \
    -H "X-Api-Key: $ADMIN" -H 'Content-Type: application/json' \
    -d '{"isAdmin":false,"session":"heitor","isActive":true,"actions":{"read":true,"send":false,"control":false,"setting":false,"app":false,"delete":false}}' \
    | python3 -c 'import json,sys; print("WAHA_READ_KEY=" + json.load(sys.stdin)["key"])' \
    >> ~/.hermes/vagas/api.env )
```

Erros na linha `Fontes indisponiveis`: `401` e chave revogada, `422` e sessao
fora do WORKING (abrir o WhatsApp no celular ou reiniciar a sessao no
dashboard), `sem resposta em 30 s` e WAHA sobrecarregado.

O script so coleta. Ele nao aplica, nao cria conta e nao envia formulario.

LinkedIn nao tem chave pessoal de busca. O limite e por IP: a VPS e datacenter,
o notebook e residencial. Com o PC ligado, `--sources linkedin-browser` passa
pelo Chromium do WSL. Sem PC, use a busca sincronizada do notebook e, para
rotina, alertas de vaga do LinkedIn lidos por `hermes-mail`. Nao use cookie de
sessao para scraping.

## Aderencia

Use `triagem.md` como referencia. Alvo: DevOps, SRE e Platform Engineering,
remoto ou Brasil, senior. Core: Kubernetes, IaC, CI/CD, GitOps/Argo CD,
observabilidade, Linux e cloud. Gaps atuais: Azure, GCP, Databricks, Jenkins,
GitLab CI, MuleSoft, service mesh, Crossplane e Vault.

Para cada vaga, informe aderencia de 1 a 5, requisitos cobertos com evidencia,
gaps reais, idioma, o que enfatizar e o que omitir. Nao invente tecnologia,
numero, certificacao ou experiencia.

## Preparar

Crie `~/.hermes/vagas/aplicacoes/<slug>/` com:

- `vaga.md`: empresa, cargo, link, idioma, requisitos e foco.
- `cv-derivado.md`: derivado do base no idioma certo, seguindo as regras.
- `carta.md`: problema da vaga, evidencia e encaixe, sem clichê.
- `respostas.md`: idioma, local, faixa salarial, disponibilidade e pendencias.
- `checklist.md`: arquivos, perguntas do formulario e o que falta.
- `email.md`: rascunho com `Para:` e `Assunto:` no topo, quando a vaga for por
  e-mail.

Gere o PDF na VPS, sem Chromium:

```bash
hermes-cv ~/.hermes/vagas/aplicacoes/<slug>/cv-derivado.md \
  --out "$HOME/.hermes/vagas/aplicacoes/<slug>/Heitor Freitas Ferreira - CV.pdf" \
  --lang en
```

Atualize `aplicacoes.md` com data, empresa, cargo, status, link, pasta e proximo
passo. Status: `pesquisada`, `preparada`, `aplicada`, `entrevista`, `teste`,
`rejeitada`, `oferta`.

## Aplicar

O padrao e preparar e abrir o formulario para revisao. Se o Heitor pedir para
aplicar, preencha os campos conhecidos no navegador, mostre o resumo e pare antes
do botao de enviar. Nunca clique em enviar sem confirmacao explicita na mesma
conversa. Nao crie conta, nao aceite termo e nao responda teste tecnico sozinho.

Para vaga por e-mail, o envio usa o `profheitor` e o anexo do PDF:

```bash
hermes-mail send --account profheitor \
  --draft ~/.hermes/vagas/aplicacoes/<slug>/email.md \
  --attach "$HOME/.hermes/vagas/aplicacoes/<slug>/Heitor Freitas Ferreira - CV.pdf" \
  --yes
```

O `--yes` so entra depois da confirmacao. Sem ele, o comando recusa o envio.

## LinkedIn

Um post ligado a vaga usa o tema tecnico dos requisitos, nunca a empresa, o
recrutador, o link ou o status da candidatura. A skill `linkedin-posts` gera o
rascunho. O job semanal so entrega no Telegram, nao publica.
