# ns8-copilot

[SOCFortress CoPilot](https://github.com/socfortress/CoPilot) on NethServer 8: a single pane of glass for security operations, with connectors for Wazuh, Graylog, Velociraptor, Shuffle, Grafana and other SOC tools.

The module runs the official SOCFortress images of the upstream `docker-compose.yml` in a rootless Podman pod, behind Traefik.

> CoPilot holds security data and the credentials of your SOC tools. SOCFortress does not intend it to face the Internet: publish it on a private network or a VPN.

## Install

```bash
add-module ghcr.io/geniusdynamics/socfortress-copilot:latest 1
```

The command returns the instance id, for example `socfortress-copilot1`. Use the id NS8 returns.

The module image is `socfortress-copilot`, not `copilot`: the `ghcr.io/geniusdynamics/copilot` package belongs to an older repository and this repository cannot publish to it.

## Configure

```bash
api-cli run configure-module --agent module/socfortress-copilot1 --data - <<'EOF'
{
  "host": "copilot.example.org",
  "http2https": true,
  "lets_encrypt": false
}
EOF
```

Settings left out keep their current value. Every setting is also on the Settings page.

| Parameter | Required | Type | Default | CoPilot variable | Description |
|---|---|---|---|---|---|
| `host` | yes | string | | | Host name of CoPilot, like `copilot.example.org` |
| `http2https` | no | boolean | `true` | | Redirect HTTP to HTTPS |
| `lets_encrypt` | no | boolean | `false` | | Request a Let's Encrypt certificate |
| `access_token_expire_minutes` | no | integer | `1440` | `ACCESS_TOKEN_EXPIRE_MINUTES` | Lifetime of a login session, 5 to 525600 minutes |
| `audit_log_retention_days` | no | integer | `90` | `AUDIT_LOG_RETENTION_DAYS` | Days the audit log is kept, `0` keeps it forever |
| `default_alert_severity` | no | string | `High` | `DEFAULT_ALERT_SEVERITY` | Severity of the alerts whose source gives none: `Informational`, `Low`, `Medium`, `High` or `Critical` |
| `announcements_enabled` | no | boolean | `true` | `ANNOUNCEMENTS_ENABLED` | Show the SOCFortress news feed, downloaded from GitHub |
| `talon_release_check_enabled` | no | boolean | `true` | `TALON_RELEASE_CHECK_ENABLED` | Check ghcr.io for new Talon releases |
| `mail_from` | no | string | `""` | `SMTP_FROM` | Sender of the CoPilot e-mails. Empty: the smarthost user name, else `noreply@<host>` |

The module sets these CoPilot variables itself: `COPILOT_URL` and `WEBAUTHN_ORIGINS` (`https://<host>`), `WEBAUTHN_RP_ID` (`<host>`), `MYSQL_URL` and `MINIO_URL` (`127.0.0.1`), `SERVER_IP`.

### First login

CoPilot creates the `admin` user at its first start and prints its password once, in the backend log:

```bash
runagent -m socfortress-copilot1 podman logs copilot-backend 2>&1 | grep "Admin user password"
```

The password is the `plain=` value. Change it after the first login.

### E-mail

CoPilot sends e-mail (temporary passwords, customer portal notifications) through the smarthost of the cluster: the backend reads it at every start, and the module restarts the backend when the smarthost changes. CoPilot uses SMTP with STARTTLS: a smarthost with TLS from the first byte (port 465) does not work.

### Other CoPilot settings

The upstream [`.env.example`](https://github.com/socfortress/CoPilot/blob/main/.env.example) lists many more settings, for example `MDR_ENABLED`, `WAZUH_UTILS_URL` and `WAZUH_UTILS_API_KEY`, `SANDBOX_BACKEND` and the `CAPE_*` settings, `DB_POOL_SIZE`, the `PERF_*` settings, `ANNOUNCEMENTS_FEED_URL`, `CUSTOMER_PORTAL_URL`. Set them in `custom.env`, in the state directory of the instance (mode 0600, saved by the backup). Its values override the ones of the module.

```bash
runagent -m socfortress-copilot1 bash -c 'echo "AUDIT_LOG_RETENTION_DAYS=365" >> custom.env'
runagent -m socfortress-copilot1 systemctl --user restart copilot-backend.service
```

The connectors (Wazuh Indexer, Wazuh Manager, Graylog, Velociraptor and the others) are configured in the CoPilot web interface, not in the environment.

## Configuration output

```bash
api-cli run get-configuration --agent module/socfortress-copilot1
```

It returns the parameters above and:

- `mail_enabled`: the smarthost of the cluster is enabled;
- `jwt_secret_set`, `sso_state_secret_set`: the backend keys exist.

It never returns a secret.

## Images

The images of the upstream `docker-compose.yml`, declared in `build-images.sh`:

| Image | Version | Service |
|---|---|---|
| `docker.io/library/mysql` | `8.0.46-debian` | `mysql-app.service` |
| `ghcr.io/socfortress/minio` | `RELEASE.2024-09-13T20-26-02Z` | `minio-app.service` |
| `ghcr.io/socfortress/copilot-backend` | `latest@sha256:…` | `copilot-backend.service` |
| `ghcr.io/socfortress/copilot-nuclei-module` | `latest@sha256:…` | `copilot-nuclei.service` |
| `ghcr.io/socfortress/copilot-frontend` | `latest@sha256:…` | `copilot-frontend.service` |

SOCFortress publishes the CoPilot images with the `latest` tag only. The module pins the digest of each image, so an update of the module is what changes CoPilot, and Renovate opens a pull request when SOCFortress publishes a new image.

Not included:

- `copilot-mcp`, the MCP servers of the AI features: it needs an OpenAI API key and Wazuh, OpenSearch and Velociraptor reachable from the pod, and its default tokens are fixed strings. The `/api/copilot_mcp` features do not work without it.
- `copilot-inspector-runner`, `copilot-inspector` and `docker-socket-proxy`, the File Analysis sandbox: the runner starts one container per analysed file through the Docker socket. In a rootless NS8 module that would mean giving a container the Podman socket of the module user, so control of every container and secret of the instance, for one optional feature. File Analysis does not work without it.
- `copilot-customer-portal`, optional and commented out upstream.

## Pod and network

- One pod, `copilot.service`. The containers reach each other on `127.0.0.1`; the names the upstream images use (`copilot-mysql`, `copilot-minio`, `copilot-backend`, `copilot-nuclei-module`) point to `127.0.0.1` in the pod.
- Only the frontend is published, on `127.0.0.1` and the TCP port of the module, for Traefik. It listens on port 8080 in plain HTTP with the site of `imageroot/etc/copilot-frontend.conf.template`: the upstream site listens on 80 and 443 with a self-signed certificate, Traefik terminates TLS here, and port 80 belongs to the Nuclei module.
- Each unit is started only once its service answers: MySQL, MinIO, the backend API, the Nuclei module and nginx. The first start of the backend creates the database and runs the migrations, which takes a few minutes.
- Runs rootless and declares the `traefik@node:routeadm` authorization.

## Secrets

Generated at install, in files of the state directory with mode 0600, never in the module environment:

- `mysql.env`: the MySQL root and `copilot` passwords;
- `minio.env`: the MinIO root account;
- `secrets.env`: `JWT_SECRET`, `SSO_STATE_SECRET`, `TOTP_ENCRYPTION_KEY`, `WAF_TOKEN_ENCRYPTION_KEY`;
- `smarthost.env`: the smarthost settings, written at every start of the backend;
- `custom.env`: the settings set by hand.

## Backup

The backup saves (`imageroot/etc/state-include.conf`):

- `state/copilot.sql`, a dump of the database (`bin/module-dump-state`), loaded again by `restore-module/40restore_database`;
- `state/mysql.env`, `state/minio.env`, `state/secrets.env`, `state/custom.env`;
- `volumes/copilot-data`, the data directory of the backend;
- `volumes/minio-data`, the MinIO objects (cases, reports, Sysmon configurations, Velociraptor artifacts);
- `volumes/nuclei-reports`, the Nuclei reports.

Restore and clone call `configure-module` with every setting of the source, and Let's Encrypt off: the DNS name may not point to the new node yet.

## Services

- `copilot.service`, the pod
- `mysql-app.service`
- `minio-app.service`
- `copilot-backend.service`
- `copilot-nuclei.service`
- `copilot-frontend.service`

## Update and uninstall

```bash
api-cli run update-module --data '{"module_url":"ghcr.io/geniusdynamics/socfortress-copilot:latest","instances":["socfortress-copilot1"],"force":true}'
remove-module --no-preserve socfortress-copilot1
```

## Testing

- `Publish images` builds the module image on every push.
- `Test module` installs the image on a QEMU NS8 node (Rocky Linux 9 and Debian 13) and runs the Robot Framework suite in `tests/`, after `Publish images` succeeds.

The suite installs the module, configures it, reads the settings back and checks that no secret is in them, waits for the frontend and the `/api/auth/sso/status` endpoint of the backend through Traefik, checks that the admin password is in the backend log and removes the module.

Run it locally with the NS8 standard infrastructure described in the [ns8-github-actions README](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally).

## Upstream

- Code: https://github.com/socfortress/CoPilot
- Documentation: https://docs.socfortress.co

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
