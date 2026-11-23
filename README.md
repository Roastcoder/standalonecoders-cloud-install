# StandaloneCoders Cloud

```text
  ███████╗ ██████╗    ██████╗██╗      ██████╗ ██╗   ██╗██████╗
  ██╔════╝██╔════╝   ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
  ███████╗██║        ██║     ██║     ██║   ██║██║   ██║██║  ██║
  ╚════██║██║        ██║     ██║     ██║   ██║██║   ██║██║  ██║
  ███████║╚██████╗   ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
  ╚══════╝ ╚═════╝    ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝
  StandaloneCoders Cloud installer   mail · WhatsApp AI · safe updates
```

<p>
  <a href="https://github.com/Roastcoder/standalonecoders-cloud-install/stargazers"><img src="https://img.shields.io/github/stars/Roastcoder/standalonecoders-cloud-install?style=for-the-badge&color=B9FF66&labelColor=101211&logo=github" alt="Stars" /></a>
  <a href="https://github.com/Roastcoder/standalonecoders-cloud-install/discussions"><img src="https://img.shields.io/badge/Questions-Discussions-B9FF66?style=for-the-badge&labelColor=101211&logo=github" alt="Discussions" /></a>
</p>

A self-hosted deploy platform for your own servers, built on [Coolify](https://github.com/coollabsio/coolify) (Apache-2.0) and extended by StandaloneCoders.

This repository only holds the install steps and scripts. The platform itself ships as a public Docker image:

| Image | `ghcr.io/roastcoder/standalonecoders-cloud:latest` |
|---|---|
| Base | Coolify 4.x |
| Architectures | amd64, arm64 |
| Access | Public: no account or token needed |

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
- Ports **22, 80, 443 and 8000** open.

## Option A: New server

1. Log in to the server as root:
   ```bash
   ssh root@your-server-ip
   ```
2. Run the installer:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Roastcoder/standalonecoders-cloud-install/main/install.sh | bash
   ```
   It installs Docker and the base platform, then StandaloneCoders Cloud. This takes 5 to 10 minutes. Each step shows a progress spinner, and the full log is kept in `/tmp/standalonecoders-install.log`.
3. Open `http://your-server-ip:8000` and create the first admin account. **Do this straight away**: until an admin exists, anyone who opens the page can register.
4. In **Settings**, set your panel domain (for example `https://cloud.example.com`) so it gets HTTPS.

## What the installer looks like

Each step is numbered, long steps show a spinner, and a failed step shows the error in red with the last lines of the log.

```text
  ███████╗ ██████╗    ██████╗██╗      ██████╗ ██╗   ██╗██████╗
  ██╔════╝██╔════╝   ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
  ███████╗██║        ██║     ██║     ██║   ██║██║   ██║██║  ██║
  ╚════██║██║        ██║     ██║     ██║   ██║██║   ██║██║  ██║
  ███████║╚██████╗   ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
  ╚══════╝ ╚═════╝    ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝
  StandaloneCoders Cloud installer   mail · WhatsApp AI · safe updates

[1/4] Checking the existing installation
      Found an installation in /data/coolify/source. Your projects and data stay.

[2/4] Downloading StandaloneCoders Cloud
      ✓ Pulling the image

[3/4] Backing up your data
      ✓ Database
      Saved to /data/coolify/backups/before-standalonecoders/database-20261123-062721.sql

[4/4] Switching the panel to StandaloneCoders Cloud
      ✓ Downloading the settings
      ✓ Restarting the panel (about a minute; your apps keep running)

  ┃ ✓ StandaloneCoders Cloud is running
  ┃ Open    http://your-server-ip:8000 (or your panel domain)
  ┃ Update  Settings → Updates in the panel
  ┃ Log     /tmp/standalonecoders-install.log
```

## Option B: You already run Coolify (original or an older version)

Your projects, apps, databases, servers, domains and settings all stay. Only the panel itself changes.

1. **Check your version.** The installer stops if your Coolify is newer than StandaloneCoders Cloud, because going back in version can damage the database. Wait for our next release in that case.
2. **Make your own backup** too (recommended): in Coolify go to **Settings → Backup** and run a backup, or copy `/data/coolify` off the server.
3. Log in to the server as root and run the installer:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Roastcoder/standalonecoders-cloud-install/main/install.sh | bash
   ```
   What it does, in order:
   1. Downloads StandaloneCoders Cloud.
   2. Checks that it is not a downgrade.
   3. Backs up the panel database and `.env` to `/data/coolify/backups/before-standalonecoders/`.
   4. Adds `/data/coolify/source/docker-compose.custom.yml`, which points the panel at our image.
   5. Restarts only the panel container. Your apps keep running, and the panel is offline for about a minute.
4. Open your panel as usual and log in with your existing account.

### Coming from an older StandaloneCoders install

Run the same command as Option B. The installer sees the older version and updates it in place.

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
| `Could not download` | The server cannot reach `ghcr.io`. Check its internet connection and DNS, then run the installer again. |
| `newer than StandaloneCoders Cloud` | Wait for our next release, or run again with `FORCE=1` only if you accept the risk. |
| Panel shows "restarting" for more than 5 minutes | Run `docker logs coolify --tail 50` on the server and send us the output. |

To restore a backup: `cat /data/coolify/backups/before-standalonecoders/database-<time>.sql | docker exec -i coolify-db psql -U coolify -d coolify`

## Questions and support

Ask in [Discussions](https://github.com/Roastcoder/standalonecoders-cloud-install/discussions). Someone may already have hit the same problem, and the answer helps the next person too. If StandaloneCoders Cloud is useful to you, a ⭐ on this repo helps others find it.

## License

The install scripts in this repository are free to use. StandaloneCoders Cloud is built on [Coolify](https://github.com/coollabsio/coolify), licensed under Apache-2.0. Coolify is a trademark of its owners, and this project is not affiliated with or endorsed by coollabsio.
