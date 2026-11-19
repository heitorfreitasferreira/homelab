# Operacao do homelab

Rotina pelo Hermes na racknerd. Mudanca pesada de infraestrutura pelo OpenCode no
notebook. O cluster e GitOps: o repo e a fonte de verdade, o Argo reconcilia.

## Fonte de verdade

- `main` de `github.com/heitorfreitasferreira/homelab`.
- `DECISIONS.md` explica o porque de cada escolha. Leia antes de propor mudanca.
- `clusters/homelab/apps/*.yaml` declara uma Application do Argo por chart.
- `apps/<nome>/` guarda os manifests Kustomize.
- `platform/` guarda base, CoreDNS e Tailscale.
- O dado vivo vence o repo na hora de diagnosticar. O repo vence na hora de mudar.

Nunca edite o cluster ao vivo para "resolver rapido". Se precisar, registre a
excecao, reconcilie no repo e deixe o Argo voltar ao estado declarado.

## Nos

- `racknerd`: VPS Debian 13, k3s de um no, sempre ligada. Roda Argo CD, Nextcloud,
  Securo, Pi-hole, monitoring, MCPs, Hermes e OpenCode. Nada exposto fora da
  tailnet, exceto SSH e a VPN.
- `pc-heito-wsl`: WSL2 no PC do Heitor, 4 vCPU e 8 GB, efemero. Tem o taint
  `homelab.io/compute=true:NoSchedule` e o label
  `node.kubernetes.io/exclude-from-external-load-balancers=true`. Recebe so
  `apps/hermes-browser` e `apps/hermes-whisper`. Quando o PC desliga, os pods
  ficam Pending e o Argo mostra `Progressing`. Isso e normal.
- `casa`: Positivo C14CR21, Debian 13, Podman Quadlet. Roda Home Assistant e
  Matter Hub e e subnet router de `192.168.100.0/24`.
- Notebook: OpenCode, Zed e os MCPs locais. Nao e servidor. Use para mudancas
  grandes, diagnostico profundo e trabalho que exige o checkout completo.

## Fluxo de mudanca

1. Rode `hermes-ops status` e leia o estado dos nos, apps do Argo, pods fora de
   `Running` e alertas.
2. Leia o arquivo que vai mudar e o `DECISIONS.md` relacionado.
3. Edite so o necessario. Mantenha o estilo do repo.
4. Valide YAML com `python3 -c 'import yaml...'` ou o teste que o app ja usa.
5. Rode `hermes-ops publish "mensagem do commit"`. O script faz `git pull
   --ff-only`, recusa arquivo com cara de segredo, commita e faz push pela deploy
   key da racknerd.
6. O Argo sincroniza `main` sozinho. Se a app nao pegar, rode
   `hermes-ops sync <app>`.
7. Verifique o recurso de verdade: pod `Running`, log sem erro, endpoint
   respondendo, metrica ou alerta. Nao confie so no `Synced`.
8. Rollback e `hermes-ops revert <sha>`, que cria um commit de revert e faz push.

## CLI hermes-ops

Instalado root-owned em `/usr/local/sbin/hermes-ops`. O fonte fica em
`ops/hermes-ops` no repo. O Hermes pode executar o CLI, mas nao editar a copia
instalada.

```bash
hermes-ops status
hermes-ops sync monitoring-grafana
hermes-ops logs monitoring grafana-xxxxx 200
hermes-ops restart homepage homepage
hermes-ops publish "monitoring: ajusta alerta"
hermes-ops revert 1a2b3c4
```

- `status` e somente leitura.
- `sync` so dispara refresh e sync do Argo, nao aplica manifesto na mao.
- `restart` aceita apenas os namespaces `monitoring`, `homepage`, `hermes`,
  `nextcloud`, `securo` e `pihole`.
- `publish` recusa `.env`, tokens, chaves e kubeconfig. Mesmo assim, revise o
  `git status` antes.
- `revert` so aceita commit que esta no historico do `main`.

## Argo CD

- App raiz: `root`, aponta para `clusters/homelab`. Ela cria as Applications
  filhas por sync wave.
- `Synced` significa que o manifesto aplicado bate com o repo. `Healthy`
  significa que o recurso esta pronto. Um app pode estar `Synced` e `Progressing`.
- `OutOfSync` depois de um push: espere a proxima reconciliacao ou rode
  `hermes-ops sync <app>`.
- `Degraded` e falha real. Leia os eventos, o log do pod e o historico do Argo.
- `Progressing` em `hermes-browser` ou `hermes-whisper` com o PC desligado e
  esperado.
- Rollback de app e revert de commit. Nao use `kubectl rollout undo` como
  rotina, porque o Argo reaplica o estado do repo.
- A conta `mcp` do Argo e read-only. Escrita so pelo `hermes-ops` ou pelo
  OpenCode.

## Monitoring

- VictoriaMetrics single em `monitoring`, retencao de 90 dias.
- vmalert avalia as regras, o Alertmanager entrega no Telegram e pinga o
  Healthchecks.io.
- Grafana em `https://grafana.tail76c1c6.ts.net`, admin com a senha em
  `~/.config/opencode-secrets/grafana-admin.txt` no notebook.
- Dashboards proprios em `apps/monitoring/dashboards/*.json`, publicados por
  ConfigMap com `grafana_dashboard=1`.
- Alertas em `clusters/homelab/apps/monitoring.yaml`. O arquivo tem um bloco
  YAML embutido que quebra validador de arquivo inteiro, entao edite com replace
  de string e valide a expressao contra o vmsingle.
- O WSL nao entra em alerta de disponibilidade, RAM, disco, pressao, restart ou
  OOM. Se for mexer nesses alertas, preserve os matchers `node!="pc-heito-wsl"`.
- Consultas rapidas:
  `curl -G https://metricas.tail76c1c6.ts.net/api/v1/query --data-urlencode 'query=ALERTS{alertstate="firing"}'`.

## k3s e host

- Servicos systemd: `hermes-gateway`, `hermes-dashboard`, `opencode`, `anytype`
  (usuario) e os servicos do k3s.
- Logs: `journalctl -u hermes-gateway -n 100 --no-pager` e
  `~/.hermes/logs/gateway.log`.
- A VPS tem 6 GB de RAM e 8 GB de swap. Antes de subir algo, olhe `free -m` e o
  consumo dos pods. O dashboard do Hermes e os MCPs stdio sao os maiores
  consumidores.
- Nao reinicie o `hermes-gateway` de dentro do Hermes. O processo nao reinicia a
  si mesmo. Peça ao Heitor ou use o OpenCode.
- `pc-heito-wsl` usa `hostNetwork` para browser e Whisper porque o CNI do WSL nao
  entrega DNS/egress aos pods. Nao troque para ClusterIP sem testar DNS e saida.

## Tailscale

- Acesso e so pela tailnet. A VPS so tem SSH publico e a VPN.
- Ingresses usam `ingressClassName: tailscale` e o ProxyGroup compartilhado
  `ingress`. Servico novo so entra depois de aprovacao no admin do Tailscale.
- `tailscale` app pode ficar `Progressing` por causa do ProxyGroup. Confira o
  Ingress e o pod do proxy antes de tratar como falha.
- Nunca exponha nada na internet. Cloudflare Tunnel so onde ja esta documentado.

## Hermes e Geoffrey

- `hermes-gateway.service` roda como `htr`, cwd `/home/htr/homelab`, e carrega o
  `AGENTS.md` do repo no system prompt.
- MCPs de leitura: Kubernetes, Argo CD, Grafana, Tailscale e Pi-hole. HA so
  leitura de contexto. Anytype com escrita sem delete.
- Browser e STT dependem do `pc-heito-wsl`. Quando o PC esta off, a ferramenta
  falha com connection refused e isso nao e incidente.
- TTS usa Edge TTS na propria VPS e nao depende do PC.
- Vision e nativa no modelo `opencode-go/deepseek-v4.1-flash`.
- O dashboard fica em `https://racknerd.tail76c1c6.ts.net:8443`.

## Runbooks

### Ver o cluster

```bash
hermes-ops status
```

### Publicar uma mudanca

```bash
hermes-ops status
git -C /home/htr/homelab diff
hermes-ops publish "app: o que mudou"
hermes-ops sync <app>
hermes-ops status
```

### Rollback

```bash
git -C /home/htr/homelab log --oneline -10
hermes-ops revert <sha>
hermes-ops sync <app>
```

### Reiniciar um app

```bash
hermes-ops restart <namespace> <deployment>
hermes-ops logs <namespace> <pod> 200
```

### WSL desligado

- `kubectl get nodes` mostra `pc-heito-wsl` como `NotReady` ou o pod fica
  Pending.
- `hermes-browser` e `hermes-whisper` ficam `Progressing`.
- Nao apague PVC, nao remova o taint, nao tente "consertar" o nó. Quando o PC
  voltar, o k3s agent sobe e os pods voltam.
- Se o PC voltar e o pod nao agendar, confira o taint e o label do nó.

### Grafana sem login

- A senha admin esta em `~/.config/opencode-secrets/grafana-admin.txt`.
- O Secret e `monitoring/grafana-admin`, criado por SOPS.
- Nao edite o Secret na mao. Se a senha do banco divergir, o reset e
  `grafana cli admin reset-admin-password` e a atualizacao do SOPS.

## Limites

- Nunca leia, imprima ou copie segredos. Tokens ficam fora do git.
- Nunca force push, nunca reescreva historico publicado.
- Nunca altere `DECISIONS.md` sem pedir.
- Nunca rode `kubectl apply`, `helm install` ou edite recurso vivo como rotina.
- Nunca reinicie o gateway do Hermes de dentro dele.
- Mudanca de banco, storage, DNS publico ou Tailscale admin e trabalho de
  OpenCode, com janela e rollback explicito.

## Deploy key

A racknerd tem a deploy key `hermes-racknerd` com escrita so neste repo. O
`hermes-ops publish` usa essa chave via `core.sshCommand`. Nao copie a chave
para outro repo nem para outro host.
