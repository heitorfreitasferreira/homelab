# Homelab: decisoes

Fonte de verdade das escolhas do homelab pessoal. Cada decisao com o porque e o que foi descartado.

## Restricoes

- VM RackNerd `racknerd-94808de`, IP 23.254.208.229, Debian 13, 5 vCPU, 6 GB RAM, 100 GB disco, sem virtualizacao aninhada.
- Must: zero perda de dados na migracao e na operacao.
- Tudo declarado em repo (GitOps), um cluster principal (homelab) e clusters isolados para projetos separados.

## Referencias

- Trabalho: k3s + Argo CD + WAL-G + Garage + Cloudflare tunnel (vault infra-docs).
- Pessoal: github.com/heitorfreitasferreira/k8s-gitops-platform (Talos + Terraform + Cilium + MetalLB + Traefik + Argo CD).

## Decisoes

1. Kubernetes: k3s. Nos de casa entram no futuro como agents via Tailscale (`--vpn-auth`). Talos descartado: exige VM por no e a VPS nao tem virtualizacao aninhada.
2. Clusters de projetos separados: vcluster dentro do k3s principal. k3d descartado por custo de RAM.
3. Repo publico, secrets cifrados com SOPS + age. A senha mestra do usuario protege a chave age e a senha do restic.
4. Fotos: Ente Photos (S3 nativo, ML no aparelho, museum ~200 MB de RAM) substitui o Immich. Usuarios: o dono e os pais, uso basico, sem uso ativo hoje. Immich + bucket montado (rclone/JuiceFS/S3QL) descartado: FUSE sob milhares de `stat()` derruba a montagem.
5. Object storage principal: Cloudflare R2 (US$0,015/GB/mes, 10 GB gratis, egress gratis). Copia unica de backup no AWS Glacier Deep Archive via rclone. B2 descartado: cadastro travou no navegador. AWS S3 como primario descartado: US$0,09/GB de egress.
6. Conta AWS pessoal, se existir, usa profile proprio e nunca o default (a maquina tem a AWS da empresa configurada).
7. Migracao: backup completo da VM para o PC local (`~/backups/racknerd-20261112`), verificado, depois reinstall do Debian do zero. Migracao no lugar descartada: VM sem espaco e sem nada que valha preservar alem dos dados.
8. Dominio: `htrlab.duckdns.org` (A 23.254.208.229) ate o eu.org aprovar `htrlab.eu.org` (pedido `20261112192651-arf-65132`, zona ja criada no Cloudflare com NS `amir`/`yolanda.ns.cloudflare.com`). Depois: cert-manager com DNS-01 no Cloudflare.
9. DNS bloqueador: roda na VM, sem porta 53 publica. Aparelhos acessam via Tailscale. Roteador de casa fica com DNS alternativo ate existir maquina em casa.
10. Acesso remoto: Tailscale substitui o WireGuard manual.
11. Runs do TCC geradas na VM: branch `backup/vm-runs-20261112` no repo `tcc` (commit `881af6e`).

12. Postgres do Ente: backup barman do CNPG em `r2:htr-backups/cnpg/ente-db` (WAL continuo + base diaria 04:00, retencao 30 dias).
13. Firefly III: MariaDB 11.8 em StatefulSet, restaurado do dump legado com o `APP_KEY` original. Importer descartado (sem uso).
14. n8n: instalacao nova. A legada tinha 0 workflows e 0 credenciais.
15. Pi-hole: `hostNetwork` com DNS preso em `tailscale0` (100.104.129.86). Web em `:8053`, so pela tailnet. Heimdall descartado.
16. Script do BBB: CronJob `jobs/notificar-bbb` 21:00 America/Sao_Paulo.
17. Pi-hole blocklists: as listas "ticked" do Firebog, sem a categoria Malicious (URLhaus, Phishing Army e afins dão falso positivo e quebram login). 16 fontes em `apps/pihole/adlists.txt`, aplicadas via API v6 e persistidas no `gravity.db` do PVC; o repo documenta e tem `apply-adlists.sh` para reaplicar. StevenBlack (padrão migrado) mantido.

## Em aberto

- Copia off-site no AWS Glacier Deep Archive: depende da conta AWS pessoal.
- Rotacionar o token R2 `htr-ente-rw` (vazou em log) e revogar `htr-migracao-rw` depois da importacao das fotos.

Estado da VM antes do reinstall: `docs/inventario-vm-atual.md`.
