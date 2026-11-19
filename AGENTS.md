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
- Nao execute `kubectl`, `helm`, `argocd`, `sops`, `age`, `ansible-playbook`,
  `systemctl`, `git push`, `curl`, `ssh` ou `tailscale` pelo shell. Use os MCPs
  read-only para consultar. Mudanca de infraestrutura vai por commit no repo e
  pelo Argo CD.
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
- Home Assistant: MCP `home-assistant` (quando configurado).
- Conhecimento: MCP `anytype` (space do homelab, quando configurado).

## Servicos

- Nextcloud com Postgres CNPG e originais no R2 (`htr-nextcloud`).
- Securo com Postgres, Redis e anexos em local-path, backup no R2.
- Pi-hole com `hostNetwork` e DNS preso em `tailscale0`, web em `:8053`.
- Monitoring: VictoriaMetrics, vmalert, Alertmanager no Telegram e Grafana.
- Homepage em `homepage.tail76c1c6.ts.net`.
- Argo CD em `argocd.tail76c1c6.ts.net`.
- Grafana em `grafana.tail76c1c6.ts.net`.

## Operacao

- Logs do OpenCode: `journalctl -u opencode -n 100 --no-pager`.
- Logs do Hermes: `journalctl -u hermes-gateway -n 100 --no-pager` e
  `~/.hermes/logs/gateway.log`.
- Estado do Hermes: `hermes gateway status`, `hermes doctor`.
- Estado do Anytype: `systemctl --user status anytype`.
- Antes de reiniciar algo, avise e espere aprovacao. O gateway do Hermes nao
  reinicia a si mesmo.
