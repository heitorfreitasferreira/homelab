# Hermes e Anytype na racknerd

Assistente pessoal do homelab. Roda na VPS, so pela tailnet e pelo Telegram.

## O que roda

- `hermes-gateway.service` (systemd de sistema, usuario `htr`): Hermes Agent
  v0.23.2, modelo `opencode-go/deepseek-v4.1-flash`, cwd `/home/htr/homelab`.
- `hermes-dashboard.service` (systemd de sistema, usuario `htr`): dashboard web
  em `127.0.0.1:9119`, publicado pelo Tailscale serve em `:8443`.
- `anytype.service` (systemd de usuario de `htr`, linger ligado): anytype-cli
  v0.5.4, API JSON em `127.0.0.1:31012`.
- MCPs do Hermes: Grafana, Tailscale, Pi-hole, Home Assistant e Anytype.

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

## Webapp

- O gateway serve o workspace do Hermes Desktop no navegador em
  `127.0.0.1:9120` (`webapp:` no `~/.hermes/config.yaml`), publicado pelo
  Tailscale serve em `https://racknerd.tail76c1c6.ts.net:9443`, so na tailnet.
- Login com o mesmo usuario e senha do dashboard (`HERMES_DASHBOARD_BASIC_AUTH_*`
  no `.env`). No celular, Chrome com "Adicionar a tela inicial".
- O bundle e compilado por `hermes webapp --build-only`, com o Node de
  `~/.hermes/tools` no PATH. Depois de `hermes update`, recompile e reinicie o
  gateway.
- O app `ai.sol.hermes` da Play Store nao e da Nous. O app oficial e o Hermes
  Mobile, em beta fechado.

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

## Vagas

- `vagas-buscar` busca em LinkedIn guest, Remotive, RemoteOK e We Work
  Remotely. Da racknerd o LinkedIn pode falhar por rate limit, entao use a
  ultima busca sincronizada do notebook.
- Na racknerd ele tambem le os grupos de vagas do WhatsApp (Dominando Cloud e
  UberHub) pelo WAHA, com a chave somente leitura `WAHA_READ_KEY` em
  `~/.hermes/vagas/api.env`. Detalhes em `docs/vagas.md`.
- A skill `vagas` mede aderencia, prepara curriculo derivado, carta, respostas e
  checklist. O padrao e preparar e abrir o formulario, sem enviar sozinho.
- O pacote de curriculo, triagem, descricoes e busca chega no digest diario do
  notebook. Runbook em `docs/vagas.md`.

## Contexto

- `terminal.cwd` e `/home/htr/homelab`. O `AGENTS.md` do repo entra no system
  prompt.
- O agente le `DECISIONS.md`, `nixos/`, `ansible/`, `scripts/` e `docs/`.
- Escrita de arquivos limitada a `/home/htr/homelab` e `/home/htr/.hermes`
  (`HERMES_WRITE_SAFE_ROOT`).

## Permissoes

- `approvals.mode: manual`, timeout de 600 s. Comando perigoso pede aprovacao no
  Telegram.
- `approvals.deny` bloqueia leitura de segredos, `sudo`, `tailscale`, `systemctl`, `ansible-playbook`, `sops`, `age`,
  `curl`, `wget`, `ssh`, `scp`, `rsync`, `crontab`, `docker` e `podman` pelo
  shell. Commit e `git push` no repo sao permitidos.
- Grafana, Tailscale e Pi-hole ficam read-only. O Pi-hole
  tem allowlist de 29 ferramentas de leitura.
- O Home Assistant expoe so `GetLiveContext`, `GetDateTime` e `todo__get_items`.
  Controle de dispositivos fica fora do Hermes.
- O Anytype pode criar e editar objetos, mas `API-delete-*` e
  `API-batch-delete-*` estao bloqueados.
- Browser e TTS ligados. O TTS usa Edge TTS. O browser fala CDP com o Chrome do
  notebook, o mesmo em que o Heitor esta logado: veja "Browser do Hermes" abaixo.
  O STT continua fora ate virar container no PC.
- Rotina de cluster pelo `/usr/local/sbin/hermes-ops`: `status`, `sync`, `logs`,
  `restart` e `revert`. O runbook esta em `docs/operacao.md`. Os comandos crus
  (`sudo`, `ssh`, `tailscale`) continuam negados. `git add`, `git commit` e
  `git push` sao o caminho padrao de mudanca.
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
- Reinicio diario as 04:30 pelo `hermes-gateway-restart.timer`, porque os MCPs
  stdio (`lazy`, `idle_timeout_seconds: 600`) somem do indice de ferramentas com
  o gateway rodando ha muito tempo. O mesmo servico serve para o Hermes se
  reiniciar: `sudo systemctl start --no-block hermes-gateway-restart.service`.
  Units em `nixos/hosts/racknerd/agents.nix`.
- Dashboard: `sudo systemctl status hermes-dashboard` e
  `sudo journalctl -u hermes-dashboard -f`.
- Atualizar Anytype: `anytype update` e `systemctl --user restart anytype`.
- Logs do gateway em `~/.hermes/logs/gateway.log`.
- Sessoes e memoria em `~/.hermes` (2,8 GB). Anytype em `~/.config/anytype`
  (161 MB).

## Browser do Hermes

O Hermes dirige o Chrome **do notebook**, com o perfil real do Heitor. Assim ele
navega e preenche formulario com as sessoes que ja existem, e o Heitor resolve o
CAPTCHA na propria janela.

- No notebook, `~/.config/chrome-flags.conf` com duas linhas:
  `--user-data-dir=/home/heitor/.config/google-chrome-cdp` e
  `--remote-debugging-port=9222`. O perfil e uma copia do perfil real, feita com
  o Chrome fechado, porque o Chrome 136+ recusa a porta de depuracao no perfil
  padrao ("DevTools remote debugging requires a non-default data directory").
  O Chrome so escuta em `127.0.0.1`, entao precisa nascer com as duas flags.
- Publicacao na tailnet: `sudo tailscale serve --bg --tcp 9222
  tcp://127.0.0.1:9222`. Sem isso o racknerd nao alcanca a porta. Fica so na
  tailnet, nunca na LAN.
- No Hermes: `browser.cdp_url: http://100.90.131.64:9222` e
  `use_real_profile: true`.
- Teste rapido, do racknerd: `curl http://100.90.131.64:9222/json/version`.
- Se o Chrome do notebook nao estiver aberto, as ferramentas de browser falham.
  Fechar e reabrir o Chrome desfaz a flag ate ele subir de novo.
- O Chrome aceita um depurador por aba: a extensao do OpenCode e o Hermes nao
  devem usar a mesma aba ao mesmo tempo.
- O STT (Speaches) era `apps/hermes-whisper`, removido na virada e ainda sem
  substituto: `stt.provider: openai`, `stt.openai.base_url`,
  `stt.openai.model` seguem apontando para o pod que nao existe.
- Config no `~/.hermes/config.yaml`: `browser.cdp_url`, `stt.provider: openai`,
  `stt.openai.base_url`, `stt.openai.model`, `tts.provider: edge` e
  `tts.edge.voice: pt-BR-FranciscaNeural`.

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
