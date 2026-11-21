# Login unico com Pocket ID

Pocket ID em `https://auth.htrlab.duckdns.org`, OIDC com passkey, um container e SQLite.
Escolhido no lugar do Authentik por RAM: cerca de 50 MB contra 1 GB no racknerd, que
opera com 790 MB livres (DECISIONS.md, item 35).

O login local de cada app continua ligado. Se o Pocket ID cair, o admin entra pela
senha do proprio app. Nunca desligar o login local antes de testar o OIDC.

## Primeiro acesso

1. Abrir `https://auth.htrlab.duckdns.org/setup` e criar o admin (usuario, email, nome).
2. Cadastrar o passkey quando pedido. O setup so funciona ate existir a primeira conta.
3. Administracao > User Groups: criar os grupos que os apps usam (por exemplo `admins`
   e `casa`). Sem grupo, o client vale para todos os usuarios.

## Clients OIDC

Administracao > OIDC Clients > Add OIDC Client, tipo Confidential, com os callbacks:

| App           | Nome no Pocket ID | Callback                                                        |
| ------------- | ----------------- | --------------------------------------------------------------- |
| AudioBookshelf | AudioBookshelf   | `https://audio.htrlab.duckdns.org/auth/openid/callback` e `.../auth/openid/mobile-redirect` |
| Nextcloud     | Nextcloud         | `https://nuvem.htrlab.duckdns.org/apps/user_oidc/code`            |
| Grafana       | Grafana           | `https://grafana.tail76c1c6.ts.net/login/generic_oauth`           |
| Argo CD       | Argo CD           | `https://argocd.tail76c1c6.ts.net/auth/callback`                  |
| Securo        | Securo            | caminho do `oidcRedirectUri` do backend, conferir antes           |

O secret aparece uma vez, na criacao. Cada app precisa dos valores no Secret do
proprio namespace, porque Secret nao cruza namespace: `nextcloud-secrets` para o
Nextcloud, `grafana-oidc` no monitoring, e as chaves `oidc.pocketid.clientSecret`
no `argocd-secret`. O AudioBookshelf guarda o secret no proprio SQLite, pela interface.

## AudioBookshelf

Tem OIDC nativo, sem mudanca no repo.

1. Settings > Authentication > OpenID Connect Authentication.
2. Issuer URL `https://auth.htrlab.duckdns.org`, clicar em Auto-Populate.
3. Client ID e Client secret do Pocket ID.
4. Subfolder for Redirect URLs: None (o app usa subdominio proprio).
5. Match existing users by email e Auto Register ligados.
6. Group Claim `groups` so se os grupos do Pocket ID tiverem `admin`, `user` ou `guest`.
   Com o claim configurado, quem nao estiver em um desses grupos nao entra.

## Nextcloud

`user_oidc` e o app oficial. Mudanca em `apps/nextcloud/app.yaml`:

- no hook `10-apps.sh`, adicionar `occ app:install user_oidc || occ app:enable user_oidc`.
- no container, duas env vindas de `nextcloud-secrets`:
  `NEXTCLOUD_OIDC_CLIENT_ID` e `NEXTCLOUD_OIDC_CLIENT_SECRET`.
- no hook, criar o provider uma vez:

```sh
occ user_oidc:provider PocketID \
  --clientid="$NEXTCLOUD_OIDC_CLIENT_ID" \
  --clientsecret="$NEXTCLOUD_OIDC_CLIENT_SECRET" \
  --discoveryuri=https://auth.htrlab.duckdns.org/.well-known/openid-configuration \
  --scope="openid email profile groups" --group-provisioning=0 || true
```

`|| true` porque o provider ja existe nas proximas subidas. O login por senha do
Nextcloud continua valendo para o admin.

## Grafana

Em `clusters/homelab/apps/monitoring.yaml`, chart `grafana`:

```yaml
envFromSecret: grafana-oidc
grafana.ini:
  auth.generic_oauth:
    enabled: true
    name: Pocket ID
    scopes: openid email profile groups
    auth_url: https://auth.htrlab.duckdns.org/authorize
    token_url: https://auth.htrlab.duckdns.org/api/oidc/token
    api_url: https://auth.htrlab.duckdns.org/api/oidc/userinfo
    client_id: $__env{GF_OIDC_CLIENT_ID}
    client_secret: $__env{GF_OIDC_CLIENT_SECRET}
    email_attribute_name: email:primary
    skip_org_role_sync: true
    allow_sign_up: false
    auto_login: false
```

O Secret `grafana-oidc` (`GF_OIDC_CLIENT_ID`, `GF_OIDC_CLIENT_SECRET`) entra no
`apps/monitoring/secret-generator.yaml` com SOPS. O usuario admin do Grafana precisa
ter o mesmo email do Pocket ID. O login por senha continua.

## Argo CD

O Argo e instalado pelo Ansible, nao pelo GitOps: a mudanca vai em
`ansible/roles/argocd/templates/argocd.yaml.j2` e so vale depois de rodar o playbook.

```yaml
configs:
  cm:
    url: https://argocd.tail76c1c6.ts.net
    oidc.config: |
      name: Pocket ID
      issuer: https://auth.htrlab.duckdns.org
      clientID: <client id>
      clientSecret: $oidc.pocketid.clientSecret
      requestedScopes: ["openid", "profile", "email", "groups"]
  rbac:
    policy.csv: |
      g, admins, role:admin
```

O `clientSecret` fica na chave `oidc.pocketid.clientSecret` do Secret `argocd-secret`.
Enquanto o Argo nao for reinstalado, o login local do admin continua e o botao do
Pocket ID nao aparece.

## Securo

Suporta OIDC, mas o chart nao aceita secret vindo de fora por campo: o
`config.oidcClientSecret` iria em texto no values do Application, dentro do git.
Para usar OIDC e preciso migrar o chart para `global.existingSecret`, levando junto a
senha do Postgres, o Redis e o secret key que hoje sao gerados pelo Helm. Fica para
uma janela propria, com o login local ligado.

## Recuperacao

- Passkey perdido: Administracao > Users > o usuario > login code, que vale uma vez e
  permite cadastrar outro passkey.
- Pocket ID fora do ar: os apps seguem com o login local. O OIDC so falha na hora de
  entrar por ele.
- Banco do Pocket ID: `pocket-id-data` (1 GiB, local-path). O backup no R2 ainda nao
  existe, e sem ele os clients e usuarios se perdem.
