# Homelab do Heitor

Este repositorio declara o homelab pessoal. A fonte de verdade das escolhas e
`DECISIONS.md`: leia antes de propor mudanca. O resto e GitOps.

## Topologia

- `racknerd`: VPS em 23.254.208.229, **NixOS 26.05**, Tailscale. Roda o
  Nextcloud, o Securo, o Pi-hole, os audiobooks, o monitoring, o Hermes, o
  OpenCode e o Anytype. Nada e exposto fora da tailnet.
- `casa`: Positivo C14CR21, Celeron B800, 2 GB, Debian 13, Podman Quadlet.
  Roda o Home Assistant e o Matter Hub. E subnet router de `192.168.100.0/24`
  na tailnet. Ainda provisionado por Ansible (`ansible/casa.yml`).
- `pc-heito-wsl`: Windows com WSL, computacao sob demanda. Nao e servidor.
- Notebook: Arch com Omarchy, Nix em container, OpenCode com MCPs. Nao e servidor.
- Tailnet: `tail76c1c6.ts.net`. MagicDNS resolve os nos.

## Onde esta o que

- `nixos/`: config declarativa dos hosts NixOS. `nixos/README.md` tem o fluxo,
  a operacao e o runbook da virada.
- `nixos/hosts/racknerd/`: tudo do racknerd, um arquivo por assunto (containers,
  postgres, caddy, nextcloud, securo, waha, pihole, audiobooks, glance,
  monitoring, agents, backup).
- `nixos/secrets/<host>.sops.yaml`: secrets do host, cifrados com a chave age.
- `ansible/`: so o `casa` (Debian + Podman).
- `docs/`: operacao, Hermes, Geoffrey, vagas e runbooks.
- `DECISIONS.md`: decisoes numeradas com o porque e o que foi descartado.

## Regras

- Nunca leia, imprima ou copie segredos. Tokens ficam em
  `~/.config/opencode-secrets` e no `.env` do Hermes, fora do git. Arquivos
  `*.sops.yaml` sao cifrados e nao devem ser descriptografados.
- Mudanca no racknerd: editar `nixos/`, `git add`, `git commit` e `git push`.
  O comin puxa o `main` em ate 1 min e aplica. Nao edite `/etc/nixos` nem
  arquivos gerenciados pelo Nix a mao.
- Secret novo: `nixos/scripts/secret-gen nixos/secrets/racknerd.sops.yaml <chave>`
  (gera) ou `sops nixos/secrets/racknerd.sops.yaml` (valor dado). Rotacao:
  `nixos/scripts/rotacionar r2|healthchecks`.
- Nao altere `DECISIONS.md` sem pedir. Mudanca de infraestrutura: mostre o
  diff, explique o efeito e espere aprovacao.
- Excecao publica: Home Assistant em `casa.htrlab.duckdns.org`, Securo em
  `securo.htrlab.duckdns.org`, Nextcloud em `nuvem.htrlab.duckdns.org`,
  audiobooks em `audio.htrlab.duckdns.org` e pedidos em
  `pedidos.htrlab.duckdns.org`, todos no Caddy da VPS. O resto e pela tailnet.
- Escrita de arquivos permitida em `/home/htr/homelab` e `/home/htr/.hermes`.
  Fora disso, peca.
- Responda em pt-BR, curto, direto. Sem travessao, sem ponto e virgula em prosa,
  sem preambulo e sem resumo de fechamento.

## Como consultar

- Repo: `git -C /home/htr/homelab log --oneline -20` e
  `git -C /home/htr/homelab status --short`.
- Estado do host: `systemctl status`, `journalctl -u <unidade>`,
  `podman ps`, `free -m`. Deploy: `systemctl status comin` e
  `curl -s 127.0.0.1:4243/metrics | grep comin_deployment_info`.
- Metricas e logs: MCP `grafana` (Viewer, sem escrita).
- Tailnet: MCP `tailscale` (no local). Escreve policy e services: `tailnet_policy_*` e
  `tailnet_service_*` substituem o arquivo e o servico inteiros, entao leia antes e
  mande o objeto completo de volta.
- DNS: MCP `pihole` (ferramentas de leitura).
- Home Assistant: MCP `home-assistant` com escrita. O servidor nativo do HA
  (`/api/mcp`) expoe `intent__HassTurnOn/Off`, `light__HassLightSet`,
  `vacuum__HassVacuumStart/ReturnToBase/CleanArea`, `homeassistant__call_action`,
  `render_template`, `history__get_history`, `system_log__*`, `config__*` e as
  ferramentas do Spook. Agir na casa e permitido, mas avise antes de acao que
  muda estado fisico por tempo prolongado (limpeza, irrigacao, alarme).
  Fallback em `~/.hermes/scripts/ha.py` (REST com `~/.hermes/ha.env`) quando o
  MCP estiver fora. A loja da comunidade e o Marketplace nativo do HA 2026.11,
  nao existe mais instalacao separada do HACS.
- Conhecimento: MCP `anytype`. Use o space que o Heitor indicar para notas,
  decisoes e runbooks.

## Geoffrey e o space de organizacao

O assistente se chama Geoffrey. Ele e o mordomo: o Heitor conversa so com ele, na
Bot Chat do Webapp, e ele repassa o resto aos bots Carreira, Financas, Casa e Ops
(`message_agent`). O Telegram (`@personal_geoffrey_bot`) so recebe aviso urgente.
Os bots estao em `docs/hermes.md`, secao Bots. O schema, as colecoes, as areas, o
fluxo e as rotinas do Anytype estao em `docs/geoffrey.md`. Use o MCP `anytype`,
nunca escreva segredo no Anytype e nao use os spaces `7bef7m` nem `723ija`.

## Servicos

- Nextcloud 35 com Postgres 17 nativo e originais no R2 (`htr-nextcloud`).
- Securo com Postgres no mesmo cluster, Redis e anexos em `/srv/securo`.
- Audiobooks: audiobookshelf, readmeabook, prowlarr e transmission em
  `/srv/audiobooks`.
- Home Assistant em `https://casa.htrlab.duckdns.org` (publico, login) e
  `https://casa.tail76c1c6.ts.net` (tailnet). O interno e
  `http://192.168.100.207:8123`.
- Pi-hole com `hostNetwork` e DNS preso em `tailscale0`, web em `:8053`.
  E o DNS global da tailnet.
- Monitoring: VictoriaMetrics, vmalert, Alertmanager e Grafana. Os alertas vao
  para o Ops do Hermes, que filtra e passa ao Geoffrey (`docs/hermes.md`, secao
  Alertas).
- Pagina inicial (Glance) em `home.tail76c1c6.ts.net`.
- Grafana em `grafana.tail76c1c6.ts.net`, metricas em
  `metricas.tail76c1c6.ts.net`.
- OpenCode em `racknerd.tail76c1c6.ts.net` (443 da tailnet), o dashboard do
  Hermes em `racknerd.tail76c1c6.ts.net:8443` e o Webapp do Hermes em
  `racknerd.tail76c1c6.ts.net:9443`.
- Backup: wal-g (WAL e base diaria do Postgres) e restic diario, os dois no R2
  em `htr-backups`.
- Browser do Hermes: o interno, no Bot Screen de cada bot (Chromium visivel na
  racknerd). O Heitor assume a tela pelo Webapp para login, 2FA e captcha. STT
  ainda sem substituto.
- Vagas: `vagas-buscar` e skill `vagas`, runbook em `docs/vagas.md`. Preparar e
  abrir o formulario e o padrao. Nunca envie candidatura sem confirmacao.
- Email: use `hermes-mail` (`accounts`, `list`, `search`, `read`, `send`).
  Gmail por IMAP com senha de app, Hotmail por Graph somente leitura. Envio so
  com confirmacao explicita e `--yes`. Runbook na skill `multi-mail`.
- CV: `hermes-cv <md> --out <pdf>` renderiza o PDF na VPS com WeasyPrint.

## Operacao

- Mudanca: edite o repo, `git add`, `git commit` e `git push`. O comin aplica.
  Rollback: `git revert` e push, ou `nixos-rebuild --rollback` no host.
- Estado do deploy: `systemctl status comin` e `journalctl -u comin`.
- Logs do OpenCode: `journalctl -u opencode -n 100 --no-pager`.
- Logs do Hermes: `journalctl -u hermes-gateway -n 100 --no-pager` e
  `~/.hermes/logs/gateway.log`.
- Estado do Hermes: `hermes gateway status`, `hermes doctor`.
- Estado do Anytype: `systemctl --user status anytype`.
- Antes de reiniciar algo, avise e espere aprovacao.
- O gateway do Hermes reinicia todo dia as 04:30 pelo
  `hermes-gateway-restart.timer`. Se os MCPs sumirem do indice de ferramentas,
  o Hermes pode se reiniciar sozinho, sem pedir e sem sudo: avise e rode
  `date > ~/.hermes/reiniciar.pedido`. A unidade `.path` dispara o servico, que
  espera 20 s e reinicia o gateway por fora, entao a resposta sai antes da
  queda. O gateway volta em cerca de 1 min. No maximo 3 vezes a cada 15 min.
