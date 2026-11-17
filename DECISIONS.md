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
9. DNS bloqueador: roda na VM, sem porta 53 publica. Aparelhos acessam via Tailscale. Roteador de casa fica com DNS alternativo ate existir maquina em casa. Atualizado em 17 a 19: a maquina de casa existe, mas o DHCP do Huawei trava o campo de DNS.
10. Acesso remoto: Tailscale substitui o WireGuard manual.
11. Runs do TCC geradas na VM: branch `backup/vm-runs-20261112` no repo `tcc` (commit `881af6e`).

12. Postgres do Ente: backup barman do CNPG em `r2:htr-backups/cnpg/ente-db` (WAL continuo + base diaria 04:00, retencao 30 dias).
13. Firefly III: MariaDB 11.8 em StatefulSet, restaurado do dump legado com o `APP_KEY` original. Importer descartado (sem uso).
14. n8n: instalacao nova. A legada tinha 0 workflows e 0 credenciais.
15. Pi-hole: `hostNetwork` com DNS preso em `tailscale0` (100.104.129.86). Web em `:8053`, so pela tailnet. Heimdall descartado.
16. Script do BBB: removido em 2026-11-13, sem uso. O script esta no historico do git (`apps/jobs/notificar_do_bbb.py`).
17. Pi-hole blocklists: as listas "ticked" do Firebog, sem a categoria Malicious (URLhaus, Phishing Army e afins dão falso positivo e quebram login). 16 fontes em `apps/pihole/adlists.txt` (ConfigMap), sincronizadas no `gravity.db` pelo pihole-updatelists todo sábado 03:25, que também roda o gravity. Imagem `jacklul/pihole` (oficial + php/updatelists) pinada por digest. StevenBlack (padrão migrado) mantido e fora do gerenciamento.

17. No de casa `casa` (Positivo C14CR21, Celeron B800, 2 GB de RAM, Debian 13): sem agent do k3s. A BIOS reservava 512 MB para video (DVMT). No minimo, o sistema ve 1,8 GB. BIOS sem Wake-on-LAN nem religamento apos queda de energia, e a bateria nao segura carga: um nobreak evita desligamentos. Containers via Podman Quadlet em `/etc/containers/systemd`. O agent mais as reservas do kubelet (`system-reserved` e `eviction-hard` do template k3s) consumiriam cerca de 800 MB. Altera o item 1 para este no. Rede: cabo no D-Link (`enp2s0f5`), porque o Wi-Fi do Huawei isola clientes. IP `192.168.100.207` reservado no DHCP do Huawei (MAC `80:ee:73:4d:de:f4`). Tailscale como subnet router de `192.168.100.0/24`, sem aceitar DNS (`--accept-dns=false`), com a rota aprovada no painel e a expiracao da chave desligada. zram de 677 MB, tampa fechada ignorada, suspensao mascarada, watchdog iTCO de 30 s, GRUB oculto com 2 s e SSH so por chave. Wake-on-LAN nao funciona: a BIOS nao tem a opcao e nao alimenta a placa quando desligado. Sem `.link` proprio para a placa: o `50-wol.link` (so `WakeOnLan=magic`) casava antes do `99-default.link`, e o systemd aplica so o primeiro `.link` que casa. Sem `NamePolicy`, a placa virou `eth0` quando o kernel `6.12.117` refez o initramfs (14/11) e o reboot automatico de 15/11 04:30 a aplicou. O cabo ficou fora ate 16/11, o Wi-Fi (`wlp1s0`, rede `FERREIRA`) segurou ate 15/11 17:13 e caiu (`rtlwifi: AP off`, 44 quedas ate a manha seguinte). O Wi-Fi fica como reserva. Mudanca que mexe no boot (`.link`, initramfs, GRUB) so vale depois de um reboot de teste.
18. DNS da tailnet: um Pi-hole so, o do racknerd (`100.104.129.86`, item 15), como nameserver global com "Override DNS servers" ligado. O DNS do DHCP do Huawei HG8245Q2 fica travado pela firmware, entao os aparelhos de casa fora da tailnet seguem no DNS da Algar. O Pi-hole do `casa` existiu de 13/11 a 17/11 como unico nameserver e saiu: em 15/11 17:13 o `casa` caiu, e a tailnet inteira (racknerd e k3s inclusive) ficou sem DNS ate 16/11. Uma VPS ligada o tempo todo cai menos que o notebook. Custo: cerca de 190 ms na primeira consulta de cada nome. Se o racknerd cair, a saida num aparelho e `sudo tailscale set --accept-dns=false`. O racknerd nao usa o DNS da tailnet (`--accept-dns=false`, papel `tailscale`): o CoreDNS sai pelo `resolv.conf` do provedor e so `tail76c1c6.ts.net` vai ao MagicDNS (`platform/coredns`), para o cluster nao depender do pod do Pi-hole.
19. Home Assistant em Podman com `--network=host` no `casa`, imagem `ghcr.io/home-assistant/home-assistant` fixada por digest (2026.11.1), limite de 700 MB, config em `/var/lib/homeassistant`. Publicado pelo `tailscale serve` em `https://casa.tail76c1c6.ts.net` (certificado Let's Encrypt do Tailscale, so na tailnet). Como o HA 2026.11 migra o bloco `http:` do YAML para `.storage/http` uma unica vez, `use_x_forwarded_for` e `trusted_proxies` (`127.0.0.1/32`, `::1/128`) sao gravados nesse arquivo pelo papel Ansible `casa`. Integracoes: Android TV Remote, Google Cast, Alexa Devices (nativa, OTP de app autenticador; o Alexa Media Player falha no desafio anti-robo da Amazon pelo proxy, issue #3667), Solarman da comunidade `davidrapan/ha-solarman` (logger `192.168.100.156`, serie `3100175593`, porta 8899, inversor Deye string 5 kW, serie `2304068225`). Pendentes: Tuya (Smart Life) e Xiaomi Home.

## Em aberto

- Observabilidade na VPS: VictoriaMetrics, Loki em modo single-binary (retencao de 14 dias), Grafana e Alertmanager enviando ao ntfy. LGTM completo descartado (RAM). Um verificador independente no `casa` avisa por canal externo se a VPS cair.
- ntfy publico na VPS com `auth-default-access: deny-all`, tokens e limites de taxa, atras do Traefik.
- Rede: nivel 1 (endurecimento), depois roteador proprio com VLANs (IoT, cameras, servidores, convidados).
- Trocar a senha padrao do Huawei (`root`) e a senha `admin` do logger solar.
- Ligar o notebook de longe: um segundo aparelho sempre ligado na LAN (Pi Zero 2 W) e um nobreak para o notebook e a ONT.

- Copia off-site no AWS Glacier Deep Archive: depende da conta AWS pessoal.
- Rotacionar o token R2 `htr-ente-rw` (vazou em log) e revogar `htr-migracao-rw` depois da importacao das fotos.

Estado da VM antes do reinstall: `docs/inventario-vm-atual.md`.
