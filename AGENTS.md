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
- `docs/`: operacao, Hermes, Geoffrey, vagas e runbooks.
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
schema, as colecoes, as areas, o fluxo e as rotinas estao em
`docs/geoffrey.md`. Use o MCP `anytype`, nunca escreva segredo no Anytype e nao
use os spaces `7bef7m` nem `723ija`.

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
- Email: Gmail padrao `jogoshloko@gmail.com`, Gmail `profheitorfreitas@gmail.com`
  com `gmail_stdlib.py --account profheitor`, Hotmail `heitor.ff@hotmail.com`
  pela skill `hotmail-graph`, somente leitura.

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
