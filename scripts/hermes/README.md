# Automacao do Hermes no notebook

Scripts que rodam no notebook do Heitor, nao na racknerd. O notebook gera o
pacote, porque e ele que tem o workspace `~/agromercantil` e os repos de
trabalho. A racknerd recebe `~/.hermes/linkedin/latest.md` e `~/.hermes/vagas/`.

## O que roda

- `hermes-eventually`: roda `/eventually` headless no workspace agromercantil
  com `opencode run --standalone`, toda sexta as 15:00.
- `hermes-activity-digest`: le git log dos repos, o relatorio mais recente do
  `eventually`, o `ESTADO.md` dos posts, o curriculo base, a triagem de vagas e
  uma busca de vagas. Monta um pacote e envia para a racknerd. Timer diario as
  18:20.
- `hermes-linkedin-pull`: traz os rascunhos gerados pelo Hermes de
  `~/.hermes/linkedin/drafts` para
  `~/agromercantil/linkedin-posts/hermes-drafts`. Timer diario as 18:50.

Ordem de sexta: 15:00 eventually, 18:20 digest, 18:40 rascunho de LinkedIn na
racknerd, 18:50 pull dos rascunhos.

## Ferramentas da VPS

- `hermes-mail`: cliente unico de e-mail. Instalar em `/usr/local/bin` como root.
  A config fica em `~/.hermes/mail_accounts.json` (`600`), as senhas de app em
  `~/.hermes/mail_<alias>.pass` (`600`) e os tokens Graph em
  `~/.hermes/msgraph_*.json` (`600`). Leitura e envio com `--yes` explicito. O
  Hotmail e somente leitura.
- `hermes-cv`: renderiza CV Markdown em PDF A4 na VPS com WeasyPrint. Depende de
  `weasyprint`, `python3-markdown` e `poppler-utils` via apt, e do CSS em
  `~/.hermes/vagas/cv.css`.
- `hermes-books`: busca no Prowlarr, manda para o Transmission e lista a
  biblioteca do AudioBookshelf. Instalar em `/usr/local/bin`. Config em
  `~/.hermes/books.env` (`600`). Skill `livros` em `~/.hermes/skills/livros`.
- Skills de runtime: `multi-mail`, `hotmail-graph`, `vagas` e `livros` em
  `~/.hermes/skills`. O digest diario sincroniza `cv.css`, o curriculo base, as
  derivadas e as descricoes de vaga.

## Instalar

```bash
install -m 755 hermes-activity-digest hermes-eventually hermes-linkedin-pull ~/.local/bin/
install -m 644 systemd-user/*.service systemd-user/*.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now hermes-activity.timer hermes-eventually.timer hermes-linkedin-pull.timer
```

O SSH para `htr@racknerd` precisa funcionar sem senha e sem agente. O user
`heitor` precisa de linger ligado para o timer rodar sem sessao aberta.

## Testar

```bash
~/.local/bin/hermes-eventually
~/.local/bin/hermes-activity-digest
systemctl --user start hermes-activity.service
systemctl --user status hermes-activity.service --no-pager
```

O digest esperado na racknerd e `~/.hermes/linkedin/latest.md`, e o pacote de
vagas em `~/.hermes/vagas/`.
