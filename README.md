# ns8-copilot

SOCFortress CoPilot focuses on providing a single pane of glass for all your security operations needs

Module id: `copilot`. Images are pinned in `build-images.sh` and updated through reviewed changes.

## Install

```bash
add-module ghcr.io/geniusdynamics/copilot:latest 1
```

The command returns the instance id, for example `copilot1`. Use the id NS8 returns.

## Configure

```bash
api-cli run configure-module --agent module/copilot1 --data - <<'EOF'
{
  "host": "copilot.example.org",
  "http2https": true,
  "lets_encrypt": false
}
EOF
```

| Parameter | Required | Type | Description |
|---|---|---|---|
| `host` | yes | string | Host name for the application, like 'kickstart.domain.org' |
| `lets_encrypt` | yes | boolean | Request a valid Let's Encrypt certificate. |
| `http2https` | yes | boolean | Redirect all the HTTP requests to HTTPS |

## Configuration output

`get-configuration` returns: `host`, `lets_encrypt`, `http2https`.

## Images

| Image | Version |
|---|---|
| `docker.io/mariadb` | `10.11.5` |
| `ghcr.io/socfortress/copilot-backend` | `latest` |
| `ghcr.io/socfortress/copilot-frontend` | `latest` |
| `ghcr.io/socfortress/copilot-nuclei-module` | `latest` |

## Network and access

- Reserves 1 TCP port(s) on the node. The web application is published through Traefik on the configured host name.
- Runs rootless.
- Declares these NS8 authorizations: `traefik@node:routeadm`.

## Backup

The following paths are included in the NS8 backup (`imageroot/etc/state-include.conf`):

- `state/copilot.sql`
- `volumes/copilot-logs`
- `volumes/copilot-data`
- `volumes/mysql-data`

## Services

- `copilot-backend.service`
- `copilot-frontend.service`
- `copilot-nuclei.service`
- `copilot.service`
- `mariadb-app.service`

## Get the configuration

```bash
api-cli run get-configuration --agent module/copilot1
```

## Update and uninstall

```bash
api-cli run update-module --data '{"module_url":"ghcr.io/geniusdynamics/copilot:latest","instances":["copilot1"],"force":true}'
remove-module --no-preserve copilot1
```

## Testing

Continuous integration:

- `Publish images` builds the module image on every push.
- `Test module` installs the image on a QEMU NS8 node and runs the Robot Framework suite in `tests/`. It runs after `Publish images` succeeds on `dev` and on `main`.
- `Build API JSON Schema docs` and the security scan run alongside.

The suite installs the module, configures a host name, checks that the web application answers through Traefik, takes UI screenshots and removes the module.

Run it locally with the NS8 standard infrastructure described in the [ns8-github-actions README](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally).

## Open items

Found by the NS8 module standards check. These must be resolved before a stable release:

- mariadb-app.service: uses %S/state, kickstart uses %E/state
- copilot-backend.service: uses %S/state, kickstart uses %E/state
- copilot-frontend.service: uses %S/state, kickstart uses %E/state
- copilot.service: uses %S/state, kickstart uses %E/state
- copilot-nuclei.service: uses %S/state, kickstart uses %E/state
- discover-smarthost still present: remove if the app does not use SMTP
- README still has the template boilerplate
- mariadb-app.service: %S/state changed to %E/state (review the bind mounts that remain)
- copilot-backend.service: %S/state changed to %E/state (review the bind mounts that remain)
- copilot-frontend.service: %S/state changed to %E/state (review the bind mounts that remain)
- copilot.service: %S/state changed to %E/state (review the bind mounts that remain)
- copilot-nuclei.service: %S/state changed to %E/state (review the bind mounts that remain)
- imageroot/actions/configure-module/80start_services: smarthost lines removed, check the unit still starts
- imageroot/systemd/user/copilot-backend.service: smarthost lines removed, check the unit still starts
- imageroot/systemd/user/copilot-frontend.service: smarthost lines removed, check the unit still starts
- imageroot/systemd/user/copilot-nuclei.service: smarthost lines removed, check the unit still starts
- COPILOT_BACKEND_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- COPILOT_FRONTEND_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- COPILOT_NUCLEI_MODULE_IMAGE is used by the module but no image in the label provides it: leftover from the template?

## Upstream

Application documentation: https://github.com/socfortress/CoPilot/tree/v0.0.9

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
