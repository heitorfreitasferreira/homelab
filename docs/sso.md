# Login unico com Pocket ID

Pocket ID em `https://auth.htrlab.duckdns.org`, OIDC com passkey, um container e SQLite.
Escolhido no lugar do Authentik por RAM: cerca de 50 MB contra 1 GB no racknerd, que
opera com 790 MB livres (DECISIONS.md, item 35).

O login local de cada app continua ligado. Se o Pocket ID cair, o admin entra pela
senha do proprio app. Nunca desligar o login local antes de testar o OIDC.

## Clients OIDC criados

| id              | App            | Callback                                                                    |
| --------------- | -------------- | --------------------------------------------------------------------------- |
| `nextcloud`     | Nextcloud      | `https://nuvem.htrlab.duckdns.org/apps/user_oidc/code`                      |
| `grafana`       | Grafana        | `https://grafana.tail76c1c6.ts.net/login/generic_oauth`                     |
| `argo-cd`       | Argo CD        | `https://argocd.tail76c1c6.ts.net/auth/callback`                            |
| `audiobookshelf`| AudioBookshelf | `https://audio.htrlab.duckdns.org/auth/openid/callback` e `.../mobile-redirect` |
| `securo`        | Securo         | `https://securo.htrlab.duckdns.org/oauth/callback` (conferir no backend)     |

Client secrets ficam em SOPS, nunca no git em claro. Os de Argo CD e Securo nao foram
gravados: quando esses dois forem ligados, gerar um secret novo no client pela
interface do Pocket ID.

## AudioBookshelf

Tem OIDC nativo, sem mudanca no repo. O par esta em `apps/audiobookshelf/oauth.sops.yaml`:

```sh
mise exec -- sops -d apps/audiobookshelf/oauth.sops.yaml
```

1. Settings > Authentication > OpenID Connect Authentication.
2. Issuer URL `https://auth.htrlab.duckdns.org`, Auto-Populate.
3. Client ID `audiobookshelf` e o client secret do arquivo acima.
4. Subfolder for Redirect URLs: None.
5. Match existing users by email, Auto Register ligado.
6. Group Claim `groups` so se os grupos do Pocket ID tiverem `admin`, `user` ou `guest`.

## Nextcloud

Ligado em `apps/nextcloud/app.yaml`: `user_oidc` instalado e provider `PocketID` criado por um hook
`before-starting` (o `post-installation` so roda na instalacao), com as env
`NEXTCLOUD_OIDC_CLIENT_ID` e `NEXTCLOUD_OIDC_CLIENT_SECRET`, que vem de `nextcloud-secrets`.
O hook so cria o provider quando ele falta.

A pagina de login do Nextcloud mostra o botao `Login with PocketID`. A senha do admin
continua valendo. O `homelab.io/hooks-rev` no Deployment existe porque mudar o ConfigMap
do hook nao reinicia o pod: subir o numero quando o script mudar.

## Grafana

Ligado em `clusters/homelab/apps/monitoring.yaml`: `envFromSecret: grafana-oidc` e a
secao `auth.generic_oauth` no `grafana.ini`, com `client_id` e `client_secret` lidos por
`$__env{}`. O Secret `grafana-oidc` vem de `apps/monitoring/grafana-oidc.sops.yaml`.

`allow_sign_up: true` com `auto_assign_org_role: Admin`: qualquer conta do Pocket ID entra
como Admin. Isso vale porque so o admin do Pocket ID cria contas e o Grafana e so da
tailnet. Para restringir, trocar por `role_attribute_path` com um grupo `admins`.

O Pocket ID manda `email` e `preferred_username` como texto no id token, entao o Grafana
usa `email_attribute_path: email` e `login_attribute_path: preferred_username`.

## Argo CD

Nao ligado. O Argo e instalado pelo Ansible, entao a mudanca vai em
`ansible/roles/argocd/templates/argocd.yaml.j2` e so vale depois de rodar o playbook:

```yaml
configs:
  cm:
    url: https://argocd.tail76c1c6.ts.net
    oidc.config: |
      name: Pocket ID
      issuer: https://auth.htrlab.duckdns.org
      clientID: argo-cd
      clientSecret: $oidc.pocketid.clientSecret
      requestedScopes: ["openid", "profile", "email", "groups"]
  rbac:
    policy.csv: |
      g, admins, role:admin
```

O secret vai na chave `oidc.pocketid.clientSecret` do Secret `argocd-secret`, por
`kubectl -n argocd patch secret`. O login local do admin continua.

## Securo

Nao ligado. Suporta OIDC, mas o chart nao aceita secret de fora por campo: o
`config.oidcClientSecret` iria em texto no values do Application. Para usar OIDC e
preciso migrar o chart para `global.existingSecret`, levando junto a senha do Postgres,
o Redis e o secret key que hoje sao gerados pelo Helm. Janela propria, com o login local
ligado.

## Recuperacao

- Passkey perdido: Administracao > Users > o usuario > login code, que vale uma vez e
  permite cadastrar outro passkey.
- Pocket ID fora do ar: os apps seguem com o login local. O OIDC so falha na hora de
  entrar por ele.
- Banco do Pocket ID: `pocket-id-data` (1 GiB, local-path). Sem backup no R2, os clients
  e usuarios se perdem com o volume.
