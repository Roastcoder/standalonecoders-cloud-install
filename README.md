# StandaloneCoders Cloud

A self-hosted deploy platform for your own servers, built on [Coolify](https://github.com/coollabsio/coolify) (Apache-2.0) and extended by StandaloneCoders.

This repository only holds the install steps and scripts. The platform itself ships as a private Docker image:

| Image | `ghcr.io/roastcoder/standalonecoders-cloud:latest` |
|---|---|
| Base | Coolify 4.x |
| Architectures | amd64, arm64 |
| Access | Private: you need an access token from StandaloneCoders |

## What you get on top of Coolify

- **Mail server with webmail**: mailboxes for your domains, with a modern webmail in the panel.
- **SMS sign-in codes**: log in with a one-time code on your phone.
- **WhatsApp AI assistant**: ask about your servers and apps, and restart or redeploy from WhatsApp. It runs on a local AI model, so no API key is needed.
- **VS Code in the browser**: open any app's code from the panel.
- **One-click updates with live progress**, plus a "restarting" page instead of a Bad Gateway error while the panel updates.
- **Server patching with a progress bar**: OS package updates run in the background, and you can leave the page.
- The StandaloneCoders look and a mobile-friendly app (PWA).

## Before you start

- A server with **Ubuntu 22.04/24.04 or Debian 12**, at least **2 CPU cores, 4 GB RAM and 40 GB disk** (8 GB RAM if you want the local AI assistant).
- **Root** access over SSH.
- An **access token** from StandaloneCoders: a username (`GH_USER`) and a token (`GH_TOKEN`). [Contact us](https://standalonecoders.com) to get one.
- Ports **22, 80, 443 and 8000** open.

## Option A: New server

1. Log in to the server as root:
   ```bash
   ssh root@your-server-ip
   ```
2. Download the installer:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Roastcoder/standalonecoders-cloud-install/main/install.sh -o install.sh
   ```
3. Run it with your access details:
   ```bash
   GH_USER="your-username" GH_TOKEN="your-token" bash install.sh
   ```
   It installs Docker and the base platform, then StandaloneCoders Cloud. This takes 5 to 10 minutes.
4. Open `http://your-server-ip:8000` and create the first admin account. **Do this straight away**: until an admin exists, anyone who opens the page can register.
5. In **Settings**, set your panel domain (for example `https://cloud.example.com`) so it gets HTTPS.

## Option B: You already run Coolify (original or an older version)

Your projects, apps, databases, servers, domains and settings all stay. Only the panel itself changes.

1. **Check your version.** The installer stops if your Coolify is newer than StandaloneCoders Cloud, because going back in version can damage the database. Wait for our next release in that case.
2. **Make your own backup** too (recommended): in Coolify go to **Settings → Backup** and run a backup, or copy `/data/coolify` off the server.
3. Log in to the server as root and download the installer:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Roastcoder/standalonecoders-cloud-install/main/install.sh -o install.sh
   ```
4. Run it:
   ```bash
   GH_USER="your-username" GH_TOKEN="your-token" bash install.sh
   ```
   What it does, in order:
   1. Logs Docker in to the private image registry.
   2. Downloads StandaloneCoders Cloud.
   3. Checks that it is not a downgrade.
   4. Backs up the panel database and `.env` to `/data/coolify/backups/before-standalonecoders/`.
   5. Adds `/data/coolify/source/docker-compose.custom.yml`, which points the panel at our image.
   6. Restarts only the panel container. Your apps keep running, and the panel is offline for about a minute.
5. Open your panel as usual and log in with your existing account.

### Coming from an older StandaloneCoders install

Run the same two commands as Option B. The installer sees the older version and updates it in place.

## Updating

- In the panel: **Settings → Updates → Update**. Progress shows live.
- Or on the server: `bash /data/coolify/source/update-custom.sh`

Official Coolify upgrades also keep StandaloneCoders Cloud, because they read the same `docker-compose.custom.yml`.

## Switching back to the official Coolify

```bash
curl -fsSL https://raw.githubusercontent.com/Roastcoder/standalonecoders-cloud-install/main/switch-back.sh | bash
```

It backs up the database to `/data/coolify/backups/before-switch-back/`, removes our override file, and installs the newest official Coolify. Your projects and data stay.

## Troubleshooting

| Problem | Fix |
|---|---|
| `Login failed` | Check `GH_USER` and `GH_TOKEN`. The token needs the `read:packages` permission. |
| `Could not download` | Your token does not have access to the image yet. Ask StandaloneCoders to grant it. |
| `newer than StandaloneCoders Cloud` | Wait for our next release, or run again with `FORCE=1` only if you accept the risk. |
| Panel shows "restarting" for more than 5 minutes | Run `docker logs coolify --tail 50` on the server and send us the output. |

To restore a backup: `cat /data/coolify/backups/before-standalonecoders/database-<time>.sql | docker exec -i coolify-db psql -U coolify -d coolify`

## For the image owner: giving someone access

1. Create a separate GitHub account for installs (do not use your own token: it would give access to all your private packages).
2. GitHub → your profile → **Packages → standalonecoders-cloud → Package settings → Manage access** → add that account with **Read**.
3. Signed in as that account: **Settings → Developer settings → Personal access tokens (classic)** → new token with only **`read:packages`**.
4. Give the user that account's username and the token.

## License

The install scripts in this repository are free to use. StandaloneCoders Cloud is built on [Coolify](https://github.com/coollabsio/coolify), licensed under Apache-2.0. Coolify is a trademark of its owners, and this project is not affiliated with or endorsed by coollabsio.
