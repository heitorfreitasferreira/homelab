# Google Workspace no Hermes

Skill `productivity/google-workspace`. O Geoffrey usa para Gmail, Calendar,
Drive, Contatos, Sheets e Docs.

## Credencial

- Cliente OAuth: `hermes`, tipo Computador, no projeto `hermes-htr`.
- Client ID: `604658049002-vhko97cbut51pvegt8orno6v0ugp2bct.apps.googleusercontent.com`.
- Conta autorizada: `jogoshloko@gmail.com`, adicionada em Test users do Google
  Auth Platform. O app esta em modo Testing, entao so os test users entram.
- Em Testing, o refresh token expira em 7 dias. Para uso permanente, publique o
  app (os escopos de Gmail passam por verificacao) ou refaca o consentimento a
  cada semana.
- Arquivos na VPS, fora do git, modo 600:
  - `~/.hermes/google_client_secret.json`
  - `~/.hermes/google_token.json`

## Escopos

- Gmail read, send e modify.
- Calendar.
- Drive.
- Contacts read.
- Sheets.
- Docs.

## Verificacao

```bash
cd ~/.hermes/hermes-agent
PY=/home/htr/.hermes/installs/8dea38e9ffc5d6d3/environments/1a0a8a5b914b445a8d11162c0b07dea0/venv/bin/python
SETUP=/home/htr/.hermes/skills/productivity/google-workspace/scripts/setup.py
env HOME=/home/htr HERMES_HOME=/home/htr/.hermes $PY $SETUP --check
env HOME=/home/htr HERMES_HOME=/home/htr/.hermes $PY $SETUP --check-live
```

Em 19/11/2026: `AUTHENTICATED` e `LIVE_CHECK_OK`.

## Operacao

- O `setup.py --auth-url` precisa do Python do Hermes e de `HERMES_HOME`.
  Rodar com o `python3` do sistema falha com "Run this script in the Hermes
  environment".
- O `--auth-url` imprime a URL. O redirect e `http://localhost:1`, entao o
  navegador mostra erro. Copie a URL inteira e use `--auth-code`.
- O `setup.py` nao aceita `--services` nem `--format` nesta versao. Ele pede
  todos os escopos da lista acima.
- Se o consentimento der 403, falta a conta em Test users.
- O secret antigo do cliente `hermes` ainda esta ativo no console. Desative e
  exclua quando confirmar que o novo esta em uso.
