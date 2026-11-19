# Geoffrey: organizacao pessoal no Anytype

O Geoffrey e o bot do Telegram (`@personal_geoffrey_bot`). O Anytype e o painel
que ele mantem. O dia a dia acontece no Telegram.

## Space

- Nome: `Geoffrey's mental mind palace`
- ID: `mrtfui`
- Conta: `hermes-bot`
- A API key `hermes-homelab` tem acesso a todos os spaces e fica em
  `~/.config/hermes-secrets/anytype.token`.
- Os spaces `7bef7m` (Homelab do bot) e `723ija` (vazio) nao sao usados.

## Tipos e propriedades

- `task`: Tarefa. `done`, `due_date`, `status`, `priority`, `energy`, `area`,
  `triaged`, `linked_projects`, `tag`.
- `project`: Projeto. `area`, `status`, `next_action`, `tag`.
- `area`: Area. `descri_o`, `status`.
- `diario`: Diario. `data`.
- `revisao`: Revisao semanal. `data`.
- `note`: Nota.
- `page`: Pagina. A unica pagina de topo e `Geoffrey`.

## Colecoes

- Inbox `bafyreigmkmhodzxz5a4soptw426ai2eouw3k3qqpnsdt5zsd2mrik6oi6m`
- Hoje `bafyreiheldpyv3plqkc3dv3yikqhc7iws4naz6n2rb4jeit3ljosuhwr74`
- Semana `bafyreigyievprkldfsvu7exi4nvu2xwtloembjmzhi4cruetipg57fceku`
- Projetos `bafyreid7pwnpqnfvcpzzj3rvftv36iiu6uqyaxzqrstvmrkwli76oa6aqq`
- Areas `bafyreihr27iy2njjekyo5ea74juu6jwsnpvj2cwnjpm6rvpzepi2waq5yi`
- Diario `bafyreicqpoah5vwou4eajxz4fvnnevjvfwjyloret72uivs55oa4sf7wr4`
- Revisao `bafyreig5sgo7u4wxtymvlpv75rxbjwaerw3wwwr6cttol42b5am2bpvio4`

## Areas iniciais

| Area | ID |
|---|---|
| Trabalho | `bafyreifozlnogbnz4vmdbtdjpoyororegqls4d6owu7yhhp4uyhssvopjm` |
| Estudos/TCC | `bafyreiej7armn7cpg6ztrychebxgftq3wgu2ut5wismuchpacdfjsz3cc4` |
| Casa | `bafyreieoj4caflw6jckhogvhbpg3nlxsmarupxpx23nxeasvqxy3yhkghu` |
| Financas | `bafyreiexbkrg4lk7uynl5ypzy3mbprjbrpxrt7hke4yk4qbyzf2daoc2cq` |
| Saude | `bafyreicevmbrkkaj3eqqgonnhu3b2pi6mkt7wj4xd2rv2fhn4m2eyu3dau` |
| Homelab | `bafyreiaaa4l57ax4jwerlrnzpkzh7dwq3nrk2tjfcbjzhsvu4yn5jhdgm4` |
| Pessoal | `bafyreighqca3k7zdweus7s3zebgaxap6iz5ttx4dg2jhwd34psthldwn5y` |

Todas com `status: "Ativa"`. A colecao `Areas` contem as 7.

## Fluxo

1. Captura: o Geoffrey cria `task` ou `note` com `triaged: false` e adiciona ao
   Inbox.
2. Triagem: define area, projeto, prazo, prioridade e energia, marca
   `triaged: true`, remove do Inbox e adiciona a Hoje, Semana ou Projetos.
3. Conclusao: `done: true` e `status: "Feito"`.
4. Area nova: cria `area` com `status: "Ativa"` e adiciona a Areas. Remove area
   so se estiver vazia, tira da colecao e move o objeto para a lixeira. Avise o
   usuario.
5. Diario: no fechamento, cria `diario` com `data` do dia, nome
   `Diario AAAA-MM-DD`, corpo com o resumo, e adiciona a Diario.
6. Revisao: domingo, cria `revisao` com `data`, nome `Revisao AAAA-Www`, corpo
   com o resumo, e adiciona a Revisao.
7. Hoje e Semana: no resumo da manha, esvazia as colecoes e adiciona as tarefas
   de hoje, atrasadas e dos proximos 7 dias.

## Rotinas

Criadas em `~/.hermes/cron/jobs.json`, com entrega no Telegram e timezone
`America/Sao_Paulo`:

| Job | ID | Horario |
|---|---|---|
| Geoffrey manha | `b6e81ea251dc` | 07:30 todo dia |
| Geoffrey fechamento | `2dc7abf72c0e` | 23:00 todo dia |
| Geoffrey revisao semanal | `670528b332a8` | domingo 19:00 |

O dashboard (`https://racknerd.tail76c1c6.ts.net:8443/cron`) mostra e edita os
jobs. O CLI e `hermes cron list`, `hermes cron runs` e `hermes cron run <id>`.

## Regras

- Nunca escrever segredo, token, senha ou chave no Anytype.
- Nunca criar pagina solta no topo. A unica e `Geoffrey`.
- Area so e removida quando esta vazia, e o objeto vai para a lixeira.
- O Telegram e a interface principal. O Anytype e o painel.
- O agente usa o MCP `anytype` com `API-create-object`, `API-patch-object`,
  `API-create-collection`, `API-delete-object` e as listas.
- O teste de ponta a ponta criou uma tarefa, colocou no Inbox e o cron das 07:30
  entregou o resumo. A tarefa de teste foi apagada.

## Operacao

```bash
systemctl --user status anytype
anytype space list
hermes cron list
hermes cron runs
hermes cron run <id>
sudo journalctl -u hermes-gateway -f
```
