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
- Browser, computer-use, TTS, geracao de imagem e video, vision e X search
  desligados. Nao ha Chromium na VPS.

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
