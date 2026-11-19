# Hermes e Anytype na racknerd

Assistente pessoal do homelab. Roda na VPS, so pela tailnet e pelo Telegram.

## O que roda

- `hermes-gateway.service` (systemd de sistema, usuario `htr`): Hermes Agent
  v0.23.2, modelo `opencode-go/deepseek-v4.1-flash`, cwd `/home/htr/homelab`.
- `hermes-dashboard.service` (systemd de sistema, usuario `htr`): dashboard web
  em `127.0.0.1:9119`, publicado pelo Tailscale serve em `:8443`.
- `anytype.service` (systemd de usuario de `htr`, linger ligado): anytype-cli
  v0.5.4, API JSON em `127.0.0.1:31012`.
- MCPs do Hermes: Kubernetes, Argo CD, Grafana, Tailscale, Pi-hole, Home
  Assistant e Anytype.

## Modelo

- Provider `opencode-go`, endpoint `https://opencode.ai/zen/go/v1`, modelo
  `deepseek-v4.1-flash`.
- A chave fica em `~/.hermes/.env` como `OPENCODE_GO_API_KEY`. E a service
  account `hermes-racknerd-prod` do OpenCode Console, sem expiracao, criada em
  18/11/2026. A service account anterior foi removida.
- O Hermes detectou contexto de 1.000.000 tokens. A compressao comeca em 50%.
- A conta Go estava em 9% do limite mensal em 18/11.

## Telegram

- Reutiliza o bot `@personal_geoffrey_bot` (id 9080173042) do Alertmanager e do
  Home Assistant.
- O token esta em `~/.hermes/.env` (`TELEGRAM_BOT_TOKEN`) e em
  `~/.config/hermes-secrets/telegram.token`.
- Allowlist: `TELEGRAM_ALLOWED_USERS=8568560413`. DMs de outros usuarios sao
  ignorados (`unauthorized_dm_behavior: ignore`).
- Modo polling, sem webhook.
- O Alertmanager e o HA so enviam mensagens, nao fazem polling, entao nao
  disputam o `getUpdates`.

## Dashboard

- URL: `https://racknerd.tail76c1c6.ts.net:8443`, so na tailnet.
- Autenticacao por usuario e senha. Usuario `heitor`, senha em
  `~/.config/opencode-secrets/hermes-dashboard.txt` no notebook.
- O dashboard escuta em `127.0.0.1:9119` e o Tailscale serve publica em 8443.
  443 continua com o OpenCode.
- `dashboard.public_url` esta em `https://racknerd.tail76c1c6.ts.net:8443`. O
  hostname publico liga o gate de autenticacao mesmo com bind local.
- As variaveis `HERMES_DASHBOARD_BASIC_AUTH_USERNAME`,
  `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` e
  `HERMES_DASHBOARD_BASIC_AUTH_SECRET` ficam no `~/.hermes/.env`.
- Paginas: Chat, Sessoes, Arquivos, Modelos, Logs, Cron, Skills, Plugins, MCP,
  Canais, Webhooks, Pairing, Perfis, Config, Keys e System.
- O dashboard custa cerca de 320 MB. Ele duplica parte do runtime do gateway,
  entao a VPS fica com pouca memoria livre ate o upgrade.

## Geoffrey

- O bot se chama Geoffrey. O Telegram e a interface principal.
- A organizacao pessoal fica no space Anytype `Geoffrey's mental mind palace`
  (`mrtfui`), documentado em `docs/geoffrey.md`.
- As rotinas rodam no cron do Hermes e entregam no Telegram: manha 07:30,
  fechamento 23:00 e revisao semanal domingo 19:00.
- O dashboard tem a pagina Cron para ver, editar e disparar os jobs.

## Google Workspace

- Skill `productivity/google-workspace`, detalhes em
  `docs/google-workspace.md`.
- Token e client secret em `~/.hermes`, modo 600, fora do git.
- `--check` e `--check-live` passam. A conta `jogoshloko@gmail.com` esta em
  Test users do projeto `hermes-htr`.

## LinkedIn

- O notebook gera `~/.hermes/linkedin/latest.md` na racknerd todo dia as 18:20
  pelo `hermes-activity.timer`, com git log dos repos, relatorios do
  `eventually` e o ESTADO dos posts.
- O job `LinkedIn: rascunho semanal` roda sexta as 18:40, usa a skill
  `linkedin-posts`, salva o rascunho em `~/.hermes/linkedin/drafts` e entrega o
  texto no Telegram para revisao.
- O Hermes nao publica sozinho. O `hermes-linkedin-pull.timer` traz os rascunhos
  para `~/agromercantil/linkedin-posts/hermes-drafts` no notebook.
- Estilo e regras em `~/agromercantil/linkedin-posts/AGENTS.md`, resumidos na
  skill `linkedin-posts`.

## Contexto

- `terminal.cwd` e `/home/htr/homelab`. O `AGENTS.md` do repo entra no system
  prompt.
- O agente le `DECISIONS.md`, `apps/`, `platform/`, `ansible/` e `docs/`.
- Escrita de arquivos limitada a `/home/htr/homelab` e `/home/htr/.hermes`
  (`HERMES_WRITE_SAFE_ROOT`).

## Permissoes

- `approvals.mode: manual`, timeout de 600 s. Comando perigoso pede aprovacao no
  Telegram.
- `approvals.deny` bloqueia leitura de segredos, `sudo`, `kubectl`, `helm`,
  `argocd`, `k3s`, `tailscale`, `systemctl`, `ansible-playbook`, `sops`, `age`,
  `git push`, `curl`, `wget`, `ssh`, `scp`, `rsync`, `crontab`, `docker` e
  `podman` pelo shell.
- Kubernetes, Argo CD, Grafana, Tailscale e Pi-hole ficam read-only. O Pi-hole
  tem allowlist de 29 ferramentas de leitura.
- O Home Assistant expoe so `GetLiveContext`, `GetDateTime` e `todo__get_items`.
  Controle de dispositivos fica fora do Hermes.
- O Anytype pode criar e editar objetos, mas `API-delete-*` e
  `API-batch-delete-*` estao bloqueados.
- Browser e TTS ligados. O Chromium roda no `pc-heito-wsl` e o Hermes fala com
  ele por CDP, entao o browser so existe quando o PC esta ligado. O TTS usa Edge
  TTS e nao depende do PC.
- STT ligado com Whisper `small` no `pc-heito-wsl`. Mensagens de voz do Telegram
  sao transcritas quando o PC esta ligado.
- Rotina de cluster pelo `/usr/local/sbin/hermes-ops`: `status`, `sync`, `logs`,
  `restart`, `publish` e `revert`. O runbook esta em `docs/operacao.md`. Os
  comandos crus (`kubectl`, `sudo`, `git push`, `ssh`) continuam negados.
- Vision e nativa no modelo `opencode-go/deepseek-v4.1-flash` (input text+image).
  Imagens enviadas no Telegram vao direto para o modelo, sem OpenRouter.
- Computer-use, geracao de imagem e video e X search continuam desligados.

## Anytype

- Conta bot `hermes-bot`
  (`A9kKV4djqPdZhohU6vBPgFxa3J2mxaFCnSagQnmDC9fUbrAT`).
- Space criado pelo bot: `Homelab` (`7bef7m`), descricao "Contexto do homelab,
  decisoes, runbooks e diario do assistente."
- Chave da conta em `~/.config/hermes-secrets/anytype-create.json` e copia em
  `~/.config/opencode-secrets/anytype-bot-account.json` no notebook.
- API key `hermes-homelab` (all spaces, read-write, sem expiracao) em
  `~/.config/hermes-secrets/anytype.token`.
- O MCP `@anyproto/anytype-mcp` 2.0.3 roda por
  `~/.config/hermes/mcp/anytype.sh` e aponta para `http://127.0.0.1:31012`.
- Para o bot entrar num space seu, gere o convite no app (Share/Invite) e rode
  `anytype space join "<link>"`. A API e a CLI nao criam convite.

## Home Assistant

- MCP remoto em `https://casa.tail76c1c6.ts.net/api/mcp`.
- O token e o mesmo do Matter Hub (`/etc/matter-hub.env` na casa), copiado para
  `~/.config/hermes-secrets/home-assistant.token` e para
  `HOME_ASSISTANT_TOKEN` no `.env`.
- A substituicao de `${HOME_ASSISTANT_TOKEN}` funciona no header do MCP.

## Operacao

```bash
sudo systemctl status hermes-gateway
sudo journalctl -u hermes-gateway -f
sudo systemctl restart hermes-gateway
systemctl --user status anytype
anytype space list
hermes gateway status
hermes doctor
```

- Atualizar Hermes: `hermes update` e `sudo systemctl restart hermes-gateway`.
- Dashboard: `sudo systemctl status hermes-dashboard` e
  `sudo journalctl -u hermes-dashboard -f`.
- Atualizar Anytype: `anytype update` e `systemctl --user restart anytype`.
- Logs do gateway em `~/.hermes/logs/gateway.log`.
- Sessoes e memoria em `~/.hermes` (2,8 GB). Anytype em `~/.config/anytype`
  (161 MB).

## Capacidades no pc-heito-wsl

- `apps/hermes-browser`: Chromium headless `chromedp/headless-shell` preso ao
  `pc-heito-wsl`, com `hostNetwork` porque o CNI do WSL nao entrega DNS/egress
  aos pods. O CDP fica em `http://100.89.110.97:30922` (NodePort 30922) e o
  perfil persistente no PVC `hermes/chromium-profile`.
- `apps/hermes-whisper`: Speaches `0.8.3-cpu` com
  `Systran/faster-whisper-small`, `hostNetwork` e API OpenAI em
  `http://100.89.110.97:8000/v1`. Modelo no PVC `hermes/whisper-models`.
- Os dois pods tem `nodeSelector` do WSL e toleram o taint
  `homelab.io/compute=true:NoSchedule`. Quando o PC desliga, ficam Pending.
  Ferramenta de browser ou STT falhando com connection refused nesse estado e
  normal, nao e incidente. O Argo mostra os dois apps como `Progressing`
  enquanto o PC estiver desligado.
- Config no `~/.hermes/config.yaml`: `browser.cdp_url`, `stt.provider: openai`,
  `stt.openai.base_url`, `stt.openai.model`, `tts.provider: edge` e
  `tts.edge.voice: pt-BR-FranciscaNeural`.
- O `PRELOAD_MODELS` do Speaches 0.8.3 nao baixou o modelo. O download e manual
  e fica no PVC:
  `curl -X POST http://100.89.110.97:8000/v1/models/Systran/faster-whisper-small`.
- Se o PVC do Whisper for recriado, repita o POST antes de usar voz.
- Teste rapido do browser: `curl http://100.89.110.97:30922/json/version`.
- Teste rapido do STT: `curl http://100.89.110.97:8000/v1/models`.

## Recursos

- Gateway: cerca de 150 MB em regime, com pico de 600 MB ao carregar os MCPs.
- Dashboard: cerca de 320 MB.
- Anytype: cerca de 30 MB.
- Sem o dashboard, a VPS ficava com cerca de 700 a 800 MB disponiveis. Com ele,
  fica com cerca de 400 a 500 MB e 8 GB de swap. O dashboard mostra um aviso de
  memoria elevada nesse estado. Os MCPs stdio usam `lazy` e
  `idle_timeout_seconds: 600`.

## Pendencias

- Convite do Anytype para o space do usuario.
- Criar um token proprio do HA para o Hermes, em vez de reutilizar o do Matter
  Hub.
- Backup de `~/.hermes` e `~/.config/anytype`.
