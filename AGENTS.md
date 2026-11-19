# Homelab do Heitor

Este repositorio declara o homelab pessoal. A fonte de verdade das escolhas e
`DECISIONS.md`: leia antes de propor mudanca. O resto e GitOps.

## Topologia

- `racknerd`: VPS Debian 13 em 23.254.208.229, k3s de um no, Tailscale. Roda o
  Argo CD, o Nextcloud, o Securo, o Pi-hole, o monitoring e os MCPs. Tambem
  roda o OpenCode e o Hermes em systemd. Nada e exposto fora da tailnet.
- `casa`: Positivo C14CR21, Celeron B800, 2 GB, Debian 13, Podman Quadlet.
  Roda o Home Assistant e o Matter Hub. E subnet router de `192.168.100.0/24`
  na tailnet.
- Notebook: Ubuntu, OpenCode com MCPs. Nao e servidor.
- Tailnet: `tail76c1c6.ts.net`. MagicDNS resolve os nos.

## Onde esta o que

- `clusters/homelab/apps/*.yaml`: Applications do Argo CD, uma por chart.
- `apps/<nome>/`: manifests Kustomize dos apps.
- `platform/`: base, CoreDNS e Tailscale operator.
- `ansible/`: provisionamento da VPS e do `casa`.
- `docs/`: inventario, handoff e operacao do OpenCode.
- `DECISIONS.md`: decisoes numeradas com o porque e o que foi descartado.

## Regras

- Nunca leia, imprima ou copie segredos. Tokens ficam em
  `~/.config/opencode-secrets` e no `.env` do Hermes, fora do git. Arquivos
  `*.sops.yaml` sao cifrados e nao devem ser descriptografados.
- O caminho padrao de mudanca e editar o repo, `git add`, `git commit` e
  `git push`. O Argo reconcilia. Use o `/usr/local/sbin/hermes-ops` para status,
  sync, logs, restart e revert.
- Nao execute `kubectl`, `helm`, `argocd`, `sops`, `age`, `ansible-playbook`,
  `systemctl`, `curl`, `ssh` ou `tailscale` pelo shell. Consulta por MCP
  read-only. Mudanca de infraestrutura vai por commit no repo e pelo Argo CD.
- Nao altere `DECISIONS.md` sem pedir. Mudanca de infraestrutura: mostre o
  diff, explique o efeito e espere aprovacao.
- Nao exponha nada na internet. O acesso e pela tailnet. A VPS so tem SSH
  publico e a VPN.
- Escrita de arquivos permitida em `/home/htr/homelab` e `/home/htr/.hermes`.
  Fora disso, peca.
- Responda em pt-BR, curto, direto. Sem travessao, sem ponto e virgula em prosa,
  sem preambulo e sem resumo de fechamento.

## Como consultar

- Repo: `git -C /home/htr/homelab log --oneline -20` e
  `git -C /home/htr/homelab status --short`.
- Cluster: MCP `kubernetes` (read-only, Secret negado).
- Argo CD: MCP `argocd` (conta `mcp`, readonly).
- Metricas e logs: MCP `grafana` (Viewer, sem escrita).
- Tailnet: MCP `tailscale` (no local, risco read).
- DNS: MCP `pihole` (ferramentas de leitura).
- Home Assistant: MCP `home-assistant` (somente leitura de contexto).
- Conhecimento: MCP `anytype`. Use o space `Homelab` (`7bef7m`) para notas,
  decisoes e runbooks. Se o bot tiver sido convidado para um space seu, use o
  space que o Heitor indicar.

## Geoffrey e o space de organizacao

O assistente se chama Geoffrey. O Telegram e o `@personal_geoffrey_bot`. O
space de organizacao no Anytype e `Geoffrey's mental mind palace`, id `mrtfui`.
Use o MCP `anytype`. Nao use os spaces `7bef7m` (Homelab do bot) nem `723ija`.

### Tipos e propriedades

- `task`: Tarefa. Use `done` (checkbox), `due_date` (data ISO), `status`
  (select), `priority` (Baixa, Média, Alta), `energy` (Rápida, Média, Profunda),
  `area` (objects), `triaged` (checkbox), `linked_projects` (objects) e `tag`
  (multi_select).
- `project`: Projeto. Use `area`, `status`, `next_action` e `tag`.
- `area`: Área. Use `descri_o` (descricao) e `status`.
- `diario`: Diário. Use `data` (data ISO).
- `revisao`: Revisão semanal. Use `data` (data ISO).
- `note`: Nota.
- `page`: Página. A única página de topo é `Geoffrey`
  (`bafyreiegrx7n6ljx4xk6a6apab2c5kmxp5tzosxykwmsxt4gientqiwtiy`).

### Coleções

- Inbox `bafyreigmkmhodzxz5a4soptw426ai2eouw3k3qqpnsdt5zsd2mrik6oi6m`
- Hoje `bafyreiheldpyv3plqkc3dv3yikqhc7iws4naz6n2rb4jeit3ljosuhwr74`
- Semana `bafyreigyievprkldfsvu7exi4nvu2xwtloembjmzhi4cruetipg57fceku`
- Projetos `bafyreid7pwnpqnfvcpzzj3rvftv36iiu6uqyaxzqrstvmrkwli76oa6aqq`
- Áreas `bafyreihr27iy2njjekyo5ea74juu6jwsnpvj2cwnjpm6rvpzepi2waq5yi`
- Diário `bafyreicqpoah5vwou4eajxz4fvnnevjvfwjyloret72uivs55oa4sf7wr4`
- Revisão `bafyreig5sgo7u4wxtymvlpv75rxbjwaerw3wwwr6cttol42b5am2bpvio4`

### Áreas

- Trabalho `bafyreifozlnogbnz4vmdbtdjpoyororegqls4d6owu7yhhp4uyhssvopjm`
- Estudos/TCC `bafyreiej7armn7cpg6ztrychebxgftq3wgu2ut5wismuchpacdfjsz3cc4`
- Casa `bafyreieoj4caflw6jckhogvhbpg3nlxsmarupxpx23nxeasvqxy3yhkghu`
- Finanças `bafyreiexbkrg4lk7uynl5ypzy3mbprjbrpxrt7hke4yk4qbyzf2daoc2cq`
- Saúde `bafyreicevmbrkkaj3eqqgonnhu3b2pi6mkt7wj4xd2rv2fhn4m2eyu3dau`
- Homelab `bafyreiaaa4l57ax4jwerlrnzpkzh7dwq3nrk2tjfcbjzhsvu4yn5jhdgm4`
- Pessoal `bafyreighqca3k7zdweus7s3zebgaxap6iz5ttx4dg2jhwd34psthldwn5y`

### Fluxo

1. Captura: crie `task` ou `note` com `triaged: false` e adicione ao Inbox.
2. Triagem: defina area, projeto, `due_date`, `priority` e `energy`, marque
   `triaged: true`, remova do Inbox e adicione a Hoje, Semana ou Projetos.
3. Tarefa concluída: `done: true` e `status: "Feito"`.
4. Área nova: crie `area` com `status: "Ativa"` e adicione a Áreas. Remova área
   só se estiver vazia, remova da coleção e delete o objeto (vai para a
   lixeira). Avise o que fez.
5. Diário: no fechamento, crie `diario` com `data` do dia, nome
   `Diário AAAA-MM-DD`, corpo com o resumo, e adicione a Diário.
6. Revisão semanal: domingo, crie `revisao` com `data`, nome
   `Revisão AAAA-Www`, corpo com o resumo, e adicione a Revisão.
7. Hoje e Semana: no resumo da manhã, esvazie as coleções e adicione as tarefas
   com `due_date` de hoje, atrasadas e dos próximos 7 dias.
8. Nunca crie página solta no topo. Use as coleções.
9. Nunca escreva segredo, token, senha ou chave no Anytype.

### Rotinas

- 07:30: resumo da manhã no Telegram.
- 23:00: fechamento do dia no Telegram.
- Domingo 19:00: revisão semanal no Telegram.

## Servicos

- Nextcloud com Postgres CNPG e originais no R2 (`htr-nextcloud`).
- Securo com Postgres, Redis e anexos em local-path, backup no R2.
- Pi-hole com `hostNetwork` e DNS preso em `tailscale0`, web em `:8053`.
- Monitoring: VictoriaMetrics, vmalert, Alertmanager no Telegram e Grafana.
- Homepage em `home.tail76c1c6.ts.net`.
- Argo CD em `argocd.tail76c1c6.ts.net`.
- Grafana em `grafana.tail76c1c6.ts.net`.
- Browser e STT do Hermes no `pc-heito-wsl`: Chromium CDP em
  `http://100.89.110.97:30922` e Whisper em `http://100.89.110.97:8000/v1`.
  Quando o PC esta desligado os pods ficam Pending e as ferramentas falham. Isso
  e normal, nao e falha do cluster.
- Vagas: `vagas-buscar` e skill `vagas`, runbook em `docs/vagas.md`. Preparar e
  abrir o formulario e o padrao. Nunca envie candidatura sem confirmacao.

## Operacao

- Mudanca: edite o repo, `git add`, `git commit` e `git push`. O Argo
  sincroniza `main`. O `hermes-ops publish` faz os tres em um passo, se preferir.
- `hermes-ops status`, `sync <app>`, `logs <ns> <pod>`, `restart <ns> <deploy>`
  e `revert <sha>` cobrem a rotina. O runbook completo esta em
  `docs/operacao.md`.
- Mudanca pesada de infra, banco, storage ou DNS publico fica para o OpenCode no
  notebook, com janela e rollback explicito.
- Logs do OpenCode: `journalctl -u opencode -n 100 --no-pager`.
- Logs do Hermes: `journalctl -u hermes-gateway -n 100 --no-pager` e
  `~/.hermes/logs/gateway.log`.
- Estado do Hermes: `hermes gateway status`, `hermes doctor`.
- Estado do Anytype: `systemctl --user status anytype`.
- Antes de reiniciar algo, avise e espere aprovacao. O gateway do Hermes nao
  reinicia a si mesmo. Para apps no cluster, prefira `hermes-ops restart`.
