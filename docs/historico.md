# Historico do homelab

Resumo do que foi decidido e feito, destilado das sessoes do OpenCode. O
detalhe de cada escolha esta no `DECISIONS.md`, este arquivo serve para o agente
entender o contexto sem reler todas as conversas.

## Sessoes de origem

- `ses_e2f3e98b6ffekKmWcalohL38Ku`: VM homelab k8s no RackNerd, migracao para
  R2 e rebuild da VPS.
- `ses_e0eadd316ffeAKhJSvWuPx7tjs`: Hermes, Anytype, Telegram, Google, MCPs,
  Grafana, dashboards e o trabalho de 19/11.
- `ses_e0e603080ffep2GPkV5aGst1v7`: PC Windows como no k3s via WSL.
- `ses_e10bf2516ffetjHEf6rr79m1Ag`: monitoramento de hardware e Tailscale.
- `ses_e10d053a1ffeUicYysHo5PN3Rr`: bot do Telegram vendo itens antigos.
- `ses_e0f65a52cffemC2fGgw9d34Cyh`: Solar Man e Home Assistant.
- `ses_e1669f3ceffe1acR48N1HhZDBN`: Firefly, Ente, Nextcloud e Immich.
- `ses_e14d80258ffe15CjarWWWJFpWK`: mapa Xiaomi no Home Assistant.
- `ses_e13fb501bffe2wU653CssBHh3d`: tags NFC.
- `ses_05626da51ffeAIls0BrwMf7gGG`: setup inicial do workspace agromercantil,
  `AGENTS.md`, skills e agentes.
- `ses_fc603cb79ffe1JmpSEBHZY7FQq`: comando `eventually`.
- `ses_e34049431ffeQxMoKsULlPZDOi`: workspace multi-repo com worktrees.

## Linha do tempo

### 12/11, rebuild da VPS

- Backup completo da VM antiga para o PC local, verificado, e reinstalacao do
  Debian do zero.
- k3s de um no, Argo CD como app of apps, repo publico com SOPS e age.
- Nextcloud com Postgres CNPG e originais no R2.
- Tailscale no lugar do WireGuard manual, Pi-hole so na tailnet.
- Dominio `htrlab.duckdns.org` ate o `htrlab.eu.org` sair.
- Decisoes 1 a 18 do `DECISIONS.md`.

### 13 a 17/11, servicos e casa

- Nextcloud com Memories, importacao do Immich, backup barman no R2.
- Securo para financas, sem S3, backup diario.
- Remocao de Firefly, Ente, n8n e scripts sem uso.
- Home Assistant no `casa`, com Solarman, Tuya, Xiaomi, Alexa, Matter Hub e
  painel proprio.
- Observabilidade etapa 1 e 2, Pi-hole, DNS da tailnet, alertas no Telegram.
- Decisoes 19 a 27.

### 18/11, Geoffrey e o WSL

- Hermes Agent em systemd na racknerd, Telegram no bot existente, Anytype como
  organizacao pessoal, Google Workspace, dashboard.
- MCPs read-only de Kubernetes, Argo, Grafana, Tailscale e Pi-hole, Anytype com
  escrita, HA so leitura de contexto.
- PC Windows entrou no k3s via WSL com `pc-heito-wsl`.
- Decisoes 28 a 32.

### 19/11, capacidade sob demanda

- Senha admin do Grafana passou a vir de um Secret SOPS proprio, `grafana-admin`,
  com `admin.existingSecret`. O Secret antigo do chart era revertido pelo Helm.
- Gzip no Grafana, `honor_labels` no scrape e dashboards ajustados para o WSL.
- WSL recebeu taint `homelab.io/compute=true:NoSchedule` e o label que o tira do
  ServiceLB. O drop-in do k3s guarda os dois.
- Chromium headless e Whisper no WSL, com `hostNetwork` por causa do CNI.
- TTS Edge, vision nativa no modelo e STT no Whisper.
- Runbook e CLI `hermes-ops` para a rotina do Hermes.
- Digest de atividade e job semanal de rascunho de LinkedIn.

## Principios que vieram do workspace agromercantil

- O repo e a fonte de verdade. O cluster vivo serve para diagnosticar, nao para
  definir o estado.
- Issue e task, marco e epico. Trabalho significativo comeca e termina com
  evidencia registrada.
- Pipeline verde e o criterio de deploy concluido. Nao se declara sucesso antes.
- Nunca force push. Merge entre branches de ambiente e fast-forward-only.
- Credencial so em cofre e fora do git. Nada de token em comando ou remote.
- Antes de acao corretiva em producao, rollback explicito.
- Skill e runbook existem para o proximo agente nao repetir o erro.

## O que o Hermes aprendeu a operar

- Leitura por MCP: Kubernetes, Argo CD, Grafana, Tailscale, Pi-hole e HA.
- Escrita por `hermes-ops`: status, sync, logs, restart, publish e revert.
- Mudanca de infraestrutura vai por commit, o Argo reconcilia.
- Browser e STT dependem do PC ligado. Offline e estado normal, nao incidente.
- O gateway nao reinicia a si mesmo. O dashboard e o Telegram sao a interface.

## Pendencias

- Atualizar o item 30 do `DECISIONS.md`, que ainda diz browser e computer-use
  desligados por RAM. O browser agora roda no WSL e o computer-use continua
  desligado.
- Backup de `~/.hermes` e `~/.config/anytype` para o R2.
- Token proprio do Home Assistant para o Hermes.
- Publicar ou refazer o consentimento do Google a cada 7 dias.
- Revisar o primeiro rascunho de LinkedIn antes de publicar.
