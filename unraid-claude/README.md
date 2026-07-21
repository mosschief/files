# Claude Code for Unraid

Run Claude Code **on your Unraid server** as a password-protected browser
terminal, so you can fix and configure the box from any browser or your phone.
It stays running, reaches other containers through Docker, sees your shares and
flash config, and can SSH to the host for the deeper stuff.

```
 Your phone / laptop browser ──Tailscale──▶ Unraid
                                            └─ container: claude-code + ttyd (web terminal)
                                               ├─ docker.sock → manage other containers
                                               ├─ /boot, /mnt/user → config + shares
                                               └─ ssh → root@host for host-level ops
```

## What's in here

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds the image: Node + Claude Code + `ttyd` + `tmux` + Docker CLI + ssh/tools. |
| `entrypoint.sh` | Runs Claude in a persistent `tmux` session behind the web terminal. |
| `docker-compose.yml` | The container definition and host mounts. |
| `claude-guardrails.md` | Unraid-aware `CLAUDE.md` (seeded into the workspace) that keeps Claude from doing something reboot-fragile or destructive. **Read this.** |
| `.env.example` | API key + web-terminal password. Copy to `.env`. |
| `claude-code.xml` | Unraid **Add Container** template — manage it from the Docker tab UI instead of compose. |

## Prerequisites

1. **Tailscale on Unraid** (strongly recommended) — install the *Tailscale*
   plugin or container from Community Applications. This gives the server a
   private address you can reach from anywhere, so you never expose the web
   terminal to the internet.
2. **Compose Manager** plugin from Community Applications (to run the compose
   file from the Unraid UI). Or just use SSH + `docker compose`.
3. An **Anthropic API key** (https://console.anthropic.com/) — or plan to log in
   interactively with `claude` the first time.
4. **SSH enabled on the Unraid host** if you want host-level actions (Settings →
   Management Access, or the SSH config). Optional but useful.

## Setup

Copy this folder to the server, e.g. to `/boot/config/claude-code` or a share
like `/mnt/user/appdata/claude-code`.

```bash
cd /mnt/user/appdata/claude-code

# 1. Secrets
cp .env.example .env
nano .env                 # set ANTHROPIC_API_KEY and TTYD_CREDENTIAL

# 2. SSH key so Claude can reach the host (skip if you don't need host ops)
mkdir -p ssh && chmod 700 ssh
ssh-keygen -t ed25519 -N '' -f ssh/id_ed25519
# authorize it on the host:
cat ssh/id_ed25519.pub >> /boot/config/ssh/root.pubkeys   # persists across reboot
cat ssh/id_ed25519.pub >> /root/.ssh/authorized_keys       # for the current boot

# 3. Build and start
docker compose up -d --build
```

Then open **`http://<unraid-tailscale-or-lan-ip>:7681`**, log in with the
`TTYD_CREDENTIAL` you set, and you're at a Claude Code prompt running on the
server. Because it runs in `tmux`, you can close the tab / switch to your phone
and reconnect to the same session.

> First run: if you left `ANTHROPIC_API_KEY` blank, type `claude` and follow the
> interactive login.

### No Compose Manager? Plain `docker run`

```bash
docker build -t claude-code-unraid .
docker run -d --name claude-code --restart unless-stopped \
  -p 7681:7681 \
  --env-file .env \
  -v "$PWD/workspace:/workspace" \
  -v "$PWD/ssh:/root/.ssh:ro" \
  -v /boot:/boot \
  -v /mnt/user:/mnt/user \
  -v /var/run/docker.sock:/var/run/docker.sock \
  claude-code-unraid
```

### Prefer the Unraid Docker tab UI? Use the template

`claude-code.xml` lets you manage the container from **Docker → Add Container**
(start/stop, logs, edit variables) instead of compose. Because Unraid installs
from an image, build it once, then register the template:

```bash
cd /mnt/user/appdata/claude-code
docker build -t claude-code-unraid:latest .
cp claude-code.xml /boot/config/plugins/dockerMan/templates-user/my-claude-code.xml
```

Then in the Unraid UI: **Docker → Add Container**, pick the **claude-code**
template from the *Template* dropdown, fill in your **Anthropic API Key** and
**Web Terminal Login**, and click **Apply**. Set up the `ssh/` folder (step 2
above) first if you want host access.

> Rebuild after an update with `docker build -t claude-code-unraid:latest .`,
> then hit **Force Update** (or restart) on the container in the Docker tab.

## First things to try

- "What containers are running and is anything unhealthy?"
- "Plex keeps restarting — check its logs and tell me why."
- "My cache drive is 95% full. What's using it and what's safe to move?"
- "Add an environment variable to the qBittorrent container and restart it."

## Safety — read this

This container is powerful: it can control every other container, read your
flash config, and (with the SSH key) act as root on the host. Treat it that way.

- **Password + private network only.** Always set `TTYD_CREDENTIAL`, and only
  reach port `7681` over Tailscale or your LAN. Never port-forward it.
- **Back up the flash before letting Claude change config** (*Main → Flash →
  Flash Backup*). Unraid config lives on the USB flash; a bad edit is undone by
  restoring it.
- **`claude-guardrails.md` is the seatbelt.** It teaches Claude that Unraid's OS
  is RAM-based (changes outside `/boot`/the array vanish on reboot) and to never
  touch the array/disks without explicit confirmation. Fill in the "Server
  facts" section with your host IP and notes about fragile containers.
- Start by asking read-only questions; widen to changes once you trust it.

## Updating

```bash
docker compose build --no-cache && docker compose up -d   # rebuilds with latest Claude Code
```
