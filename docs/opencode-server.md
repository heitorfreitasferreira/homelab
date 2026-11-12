# OpenCode no servidor

Servico de fundo do OpenCode V2 na VM, acessivel so pela tailnet.

- Binario: `/home/htr/.opencode/bin/opencode` (instalado com o script oficial e `opencode upgrade --major`).
- Unidade: `/etc/systemd/system/opencode.service`, roda `opencode serve --service` como `htr`, `MemoryMax=1G`.
- Escuta em `127.0.0.1:49374`. Porta, hostname e senha ficam em `opencode service get`.
- Publicacao: `tailscale serve --bg --https=443 http://127.0.0.1:49374` gera `https://racknerd.tail76c1c6.ts.net` (tailnet only, certificado valido).
- Sem tailnet: 401 sem sessao, e nada escuta no IP publico.

## Parear um aparelho

```bash
ssh htr@racknerd '~/.opencode/bin/opencode pair --url https://racknerd.tail76c1c6.ts.net'
```

Escaneie o QR code no app OpenCode. O link vale uma vez por 5 minutos. A sessao dura 30 dias.
Trocar a senha (`opencode service set password ...`) derruba todas as sessoes.

## Operacao

```bash
systemctl status opencode
journalctl -u opencode -f
sudo tailscale serve status
```
