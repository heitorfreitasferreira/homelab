# Hermes e Anytype na racknerd

Assistente pessoal do homelab. Roda na VPS, so pela tailnet. A conversa e com o
Geoffrey, na Bot Chat do Webapp. O Telegram e o canal de aviso urgente e continua
aceitando conversa.

## O que roda

- `hermes-gateway.service` (systemd de sistema, usuario `htr`): Hermes Agent
  v0.23.2, modelo `opencode-go/deepseek-v4.1-flash`, cwd `/home/htr/homelab`.
  Um gateway so atende os 5 bots (`gateway.multiplex_profiles: true`).
  `MemoryHigh=2560M` e `MemoryMax=3G`, por causa do Bot Screen.
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

- Canal de aviso urgente. A entrada continua aberta, por escolha do Heitor em
  27/11: o Geoffrey responde la, mas o `message_agent` so existe na Bot Chat,
  entao no Telegram ele nao repassa aos especialistas.
- O Geoffrey e o Ops mandam aviso com
  `python3 ~/.hermes/scripts/avisar.py "texto"`, que le o token do `.env`. As
  rotinas do Geoffrey (manha, fechamento, revisao e lembretes) tambem saem aqui.
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

## Bots

O Heitor conversa so com o Geoffrey, na Bot Chat dele (Webapp, aba BOTS). O
Geoffrey resolve o que e dele e repassa o resto com `message_agent`. Cada bot e
um perfil do Hermes, com SOUL, memoria, skills, MCPs e crons proprios.

| Bot (perfil) | Cuida de | Skills | MCPs | cwd |
|---|---|---|---|---|
| Geoffrey (`default`) | organizacao, agenda, Anytype, e-mail pessoal, diario, lembretes, livros | `anytype-api`, `google-workspace`, `multi-mail`, `email-inbox-triage`, `hotmail-graph`, `weekly-review-planning`, `livros`, `pdf` | `anytype` | `~/homelab` |
| Carreira (`carreira`) | vagas, CV, candidaturas, LinkedIn, recrutadores | `vagas`, `linkedin-posts`, `hotmail-graph`, `email-inbox-triage`, `multi-mail`, `pdf`, `blocked-page-recovery` | nenhum | `~/.hermes/vagas` |
| Financas (`financas`) | Securo, orcamento, financiamento e obra, FGTS, holerite, 13o, ponto | `securo-finance`, `ponto-jornada`, `pdf` | `securo` | `~/.hermes` |
| Casa (`casa`) | Home Assistant: robo, ar, chuva, TV, solar, usuarios da familia | `home-assistant-ops` | `home-assistant` | `~` |
| Ops (`ops`) | NixOS e comin, alertas, Grafana, Tailscale, Pi-hole, Nextcloud, OpenCode, o proprio Hermes | `homelab-ops`, `hermes-agent`, `peer-agent-briefs`, `github` | `grafana`, `tailscale`, `pihole` | `~/homelab` |

- Perfis em `~/.hermes/profiles/<nome>/`. Titulo e descricao no `profile.yaml`
  (`ui_meta.hermes-bots.title`). Esse bloco liga o Bot Mode e o `message_agent`.
- Pedido repassado pelo Geoffrey nao roda comando que precise de aprovacao. O
  Heitor aprova abrindo o chat do especialista.
- Cada bot tem so as chaves do proprio dominio no `.env`.
- Crons: as rotinas do Geoffrey entregam em `telegram,bot-chat`. Os jobs de
  agente dos especialistas entregam em `bot-chat:default`: o Geoffrey le, decide
  o que vira aviso no Telegram e responde `[SILENT]` no resto. Os jobs so de
  script (robo, chuva, varredura do Securo, obra, vigia do LinkedIn no Hotmail)
  ficam no perfil `default`, onde estao os scripts, e entregam na Bot Chat do
  Geoffrey. A chuva roda so das 07:00 as 22:30.
- O Ops delega trabalho pesado com
  `python3 ~/.hermes/scripts/opencode-delegar.py --titulo "..." @briefing.md`:
  tenta o OpenCode do notebook (`100.90.131.64:49375`) e, sem resposta em 4 s,
  abre no da racknerd (`127.0.0.1:49374`), sempre no agente `plan`. A senha do
  notebook fica em `~/.config/hermes-secrets/opencode-notebook.password`.

## Alertas

- O Alertmanager manda tudo para `http://127.0.0.1:8644/p/ops/webhooks/alertas`
  (webhook do Hermes, so em loopback), com o token `alertmanager_hermes_webhook`
  do sops no header `X-Gitlab-Token`. Token errado volta 404.
- A rota roda `alert-backoff.py` antes de qualquer LLM: descarta duplicata e
  reavisa alerta repetido so depois de 1 h, 2 h, 4 h, 8 h e 16 h, com teto de
  24 h. O resolvido passa uma vez. Estado em
  `~/.hermes/profiles/ops/alertas-estado.json`.
- O que passa dispara o cron `[bot:ops] Triagem de alertas`, que explica causa e
  proximo passo, descarta o que nao pede acao, propoe mudanca de regra como diff
  e entrega ao Geoffrey.
- `NotificacaoFalhou` (entrega ao Hermes falhou) vai direto ao Telegram. O
  `Watchdog` continua indo para o Healthchecks.

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
- Browser e TTS ligados. O TTS usa Edge TTS. O browser e o interno do Hermes, no
  Bot Screen: veja "Browser do Hermes" abaixo. O STT continua fora ate virar
  container no PC.
- `command_allowlist` sem `reverse shell via /dev/tcp` e sem `git reset --hard`
  (tirados em 27/11). Os padroes do k3s sairam do `approvals.deny`.
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

## Securo MCP

- O MCP (`securo-mcp`, `https://securo-mcp.tail76c1c6.ts.net/mcp`) aceita so JWT
  de "External MCP access". O `sct_` do `securo.env` e da API REST e nao serve.
- Com `AGENTS_ENABLED=false` o Securo nao monta `/api/agents/mcp-tokens`. O token
  sai da funcao `mint_token` dentro do proprio container, com o usuario dono do
  workspace e 90 dias de validade, e vai para `SECURO_MCP_TOKEN` no `~/.hermes/.env`:

```bash
sudo podman exec -i securo-mcp python - <<'PY'
import uuid
from app.agents.mcp.auth import mint_token
print(mint_token(user_id=uuid.UUID("<user_id>"), workspace_id=uuid.UUID("<workspace_id>"),
                 ttl_seconds=90*86400, external=True))
PY
```

- O `user_id` sai de `workspace_members` no banco `securo` (papel `owner`). O
  workspace e o `SECURO_WORKSPACE` do `securo.env`. Grave sem imprimir, teste com
  `hermes mcp test securo` e reinicie o gateway.
- O token atual vence em 24/02/2027. O job `Securo: renovar token do MCP` avisa
  em 17/02/2027.

## Fontes de vagas com chave

- `~/.hermes/vagas/api.env` (600): `JOOBLE_KEY`, `SERPAPI_KEY`, `ADZUNA_APP_ID`,
  `ADZUNA_APP_KEY` e `WAHA_READ_KEY`. Contas do `jogoshloko@gmail.com`, criadas
  em 27/11/2026.
- Jooble: 100 buscas por dia, chave do `jooble.org` global. SerpApi: plano Free,
  250 buscas por mes. Adzuna: 25 chamadas de teste no total, ate cadastrar cartao
  e escolher plano.
- Jobscan: conta pelo Google `jogoshloko@gmail.com`, plano gratis com 5 scans
  por mes. E uma das fontes de validacao do CV, nao a unica.
- O MCP do Indeed (`mcp.indeed.com/claude/mcp`) so aceita o conector do Claude: o
  OAuth do Hermes volta `invalid_client`. A entrada `indeed` ficou com
  `enabled: false` no `config.yaml`. Vaga do Indeed chega pelo SerpApi (Google
  Jobs) e pelo Jooble.

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
  o gateway rodando ha muito tempo.
- O proprio Hermes pede reinicio sem sudo: `date > ~/.hermes/reiniciar.pedido`.
  A unidade `hermes-gateway-restart.path` ve o arquivo e roda o servico, que
  espera 20 s e reinicia, no maximo 3 vezes a cada 15 min. Units em
  `nixos/hosts/racknerd/agents.nix`.
- O `hermes gateway status` avisa que a unit esta desatualizada: e esperado,
  porque ela e do NixOS. Nunca rode `hermes gateway restart --system` nem
  `hermes gateway install`.
- Dashboard: `sudo systemctl status hermes-dashboard` e
  `sudo journalctl -u hermes-dashboard -f`.
- Atualizar Anytype: `anytype update` e `systemctl --user restart anytype`.
- Logs do gateway em `~/.hermes/logs/gateway.log`.
- Sessoes e memoria em `~/.hermes` (2,8 GB). Anytype em `~/.config/anytype`
  (161 MB).

## Browser do Hermes

Desde 27/11 o Hermes usa o navegador interno, sem depender do notebook. Cada bot
tem uma tela virtual (Bot Screen: TigerVNC, Xfce e Chromium visivel na racknerd)
com perfil de navegador proprio. O Heitor ve e assume a tela pelo Webapp: aba
BOTS, o bot, Screen, Take over. Assim ele faz login, 2FA e captcha e devolve com
Hand back.

- Pacotes no `agents.nix` (tigervnc, xfwm4, xfce4-panel, xfdesktop,
  xfce4-settings, xauth, xdpyinfo, setxkbmap, xprop, dejavu_fonts, chromium).
- Config: `browser.headed: true`, `browser.cdp_url: ''`,
  `browser.use_real_profile: false`, `bot_desktop.auto_start: true`. A tela sobe
  quando um agente precisa e para depois de 30 min sem uso
  (`bot_desktop.idle_stop_minutes`). Ela se recusa a subir com menos de 1536 MB
  livres (`bot_desktop.min_free_memory_mb`).
- Chromium: `browser.executable_path: /run/current-system/sw/bin/chromium` nos
  cinco perfis, o do `agents.nix`. O Chromium que vem com o Hermes
  (`~/.hermes/tools/chromium-1248`) nao roda na NixOS: falta `libglib-2.0.so.0`.
  O icone Browser do dock abre o mesmo binario e o mesmo perfil do agente, e o
  `Exec` dele e reescrito quando a tela sobe.
- O navegador sai pelo IP de casa. O IP do racknerd e barrado no Cloudflare do
  Indeed, Glassdoor, Catho, Jooble e Vagas.com.br. Uma politica do Chromium
  (`/etc/chromium/policies/managed/proxy-casa.json`, no `agents.nix`) manda tudo
  para `socks5://100.112.62.47:1080`, o `microsocks` do casa, e deixa
  `localhost`, `127.0.0.1`, `100.64.0.0/10` e `*.ts.net` diretos. Vale para o
  navegador do agente e para o do dock. O resto da VPS segue no link proprio.
- Temas de icone: `papirus-icon-theme`, `adwaita-icon-theme` e
  `numix-icon-theme-circle` no `agents.nix`, com `~/.icons` apontando para
  `/run/current-system/sw/share/icons`, porque o launcher do Bot Screen so
  procura tema em `/usr/share/icons` e `~/.icons`. O tema escolhido e
  Papirus-Dark.
- Comandos: `hermes -p <bot> computer-use screen status|start|stop`.
- As sessoes de site ficam no perfil de navegador de cada bot. `hermes-sessoes-bots`
  (no notebook, em `scripts/hermes/`) copia os cookies do Chrome do Heitor para
  os cinco bots, por CDP e por um tunel SSH, sem fechar o Chrome. Ficam de fora
  bancos, pagamentos, investimentos, cripto, gov.br, gerenciadores de senha,
  conta Google, Microsoft, sistemas do trabalho, paineis de infraestrutura,
  contas de IA com chave de API e os servicos do homelab.
  `--simular` mostra o que iria. Dominio em que o bot ja tem cookie fica como
  esta, salvo `--substituir`. Senha, 2FA e captcha continuam pelo Take over.
- O CDP do Chrome do notebook (`tailscale serve --tcp 9222` no notebook) ficou sem
  uso. Pode ser desligado.
- O STT (Speaches) era `apps/hermes-whisper`, removido na virada e ainda sem
  substituto: `stt.provider: openai`, `stt.openai.base_url`,
  `stt.openai.model` seguem apontando para o pod que nao existe.
- Config de voz no `~/.hermes/config.yaml`: `stt.provider: openai`,
  `stt.openai.base_url`, `stt.openai.model`, `tts.provider: edge` e
  `tts.edge.voice: pt-BR-FranciscaNeural`.

## Recursos

- Gateway: cerca de 150 MB em regime, com pico de 600 MB ao carregar os MCPs.
- Dashboard: cerca de 320 MB.
- Anytype: cerca de 30 MB.
- Bot Screen: Xvnc e Xfce em torno de 180 MB parados, mais 0,5 a 1 GB com o
  Chromium aberto numa pagina.
- Sem o dashboard, a VPS ficava com cerca de 700 a 800 MB disponiveis. Com ele,
  fica com cerca de 400 a 500 MB e 8 GB de swap. O dashboard mostra um aviso de
  memoria elevada nesse estado. Os MCPs stdio usam `lazy` e
  `idle_timeout_seconds: 600`.

## Pendencias

- Convite do Anytype para o space do usuario.
- Criar um token proprio do HA para o Hermes, em vez de reutilizar o do Matter
  Hub.
- Backup de `~/.hermes` e `~/.config/anytype`.
