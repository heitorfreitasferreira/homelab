# Automacao do Hermes no notebook

Scripts que rodam no notebook do Heitor, nao na racknerd. O notebook gera o
digest, porque e ele que tem o workspace `~/agromercantil` e os repos de
trabalho. A racknerd so recebe o Markdown em `~/.hermes/linkedin/latest.md`.

## O que roda

- `hermes-activity-digest`: le git log dos repos, os relatorios do
  `eventually` e o `ESTADO.md` dos posts, monta um Markdown e envia para a
  racknerd. Timer diario as 18:20.
- `hermes-linkedin-pull`: traz os rascunhos gerados pelo Hermes de
  `~/.hermes/linkedin/drafts` para
  `~/agromercantil/linkedin-posts/hermes-drafts`. Timer diario as 18:50.

## Instalar

```bash
install -m 755 hermes-activity-digest ~/.local/bin/
install -m 755 hermes-linkedin-pull ~/.local/bin/
install -m 644 systemd-user/*.service systemd-user/*.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now hermes-activity.timer hermes-linkedin-pull.timer
```

O SSH para `htr@racknerd` precisa funcionar sem senha e sem agente. O user
`heitor` precisa de linger ligado para o timer rodar sem sessao aberta.

## Testar

```bash
~/.local/bin/hermes-activity-digest
systemctl --user start hermes-activity.service
systemctl --user status hermes-activity.service --no-pager
```

O digest esperado na racknerd e `~/.hermes/linkedin/latest.md`.
