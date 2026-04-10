# Homelab Infrastructure

A self-hosted media and automation stack running on Ubuntu Server, managed via Docker Compose and automatically deployed via GitHub Actions. All services run in Docker containers on a dedicated `bookstack` network and are accessible by IP or via `.homelab` local DNS domains after AdGuard is configured.

---

## Storage Layout

```
┌─────────────────────────────────────────────────────────┐
│  NVMe SSD (465.8 GB)  — mounted at /                   │
│  ├── OS (Ubuntu Server)                                 │
│  └── /home/docker/    — all container config/data       │
│       ├── portainer/                                    │
│       ├── adguard/                                      │
│       ├── npm/                                          │
│       ├── jellyfin/                                     │
│       ├── audiobookshelf/                               │
│       ├── kavita/                                       │
│       ├── qbittorrent/                                  │
│       ├── prowlarr/                                     │
│       ├── radarr/                                       │
│       ├── sonarr/                                       │
│       ├── readarr/                                      │
│       └── shelfarr/                                     │
├─────────────────────────────────────────────────────────┤
│  HDD (931.5 GB)  — mounted at /home                     │
│  └── /home/media/     — all media files                 │
│       ├── movies/                                       │
│       ├── tvshows/                                      │
│       ├── audiobooks/                                   │
│       ├── books/                                        │
│       └── downloads/                                    │
│           ├── complete/                                 │
│           └── incomplete/                               │
└─────────────────────────────────────────────────────────┘
```

---

## Services

| Service | IP URL | Domain URL | Purpose |
|---|---|---|---|
| Portainer | https://IP:9443 | portainer.homelab | Docker management |
| Nginx Proxy Manager | http://IP:81 | — | Reverse proxy |
| AdGuard Home | http://IP:3000 | adguard.homelab | Local DNS & ad blocking |
| Jellyfin | http://IP:8096 | jellyfin.homelab | Movies & TV streaming |
| Audiobookshelf | http://IP:13378 | audiobookshelf.homelab | Audiobook server |
| Kavita | http://IP:5000 | kavita.homelab | Book reader |
| qBittorrent | http://IP:8080 | qbittorrent.homelab | Torrent downloader |
| Prowlarr | http://IP:9696 | prowlarr.homelab | Indexer manager |
| FlareSolverr | http://IP:8191 | — | Cloudflare bypass |
| Radarr | http://IP:7878 | radarr.homelab | Movie automation |
| Sonarr | http://IP:8989 | sonarr.homelab | TV show automation |
| Readarr | http://IP:8787 | readarr.homelab | Book & audiobook automation |
| Shelfarr | http://IP:8084 | shelfarr.homelab | Book downloader |

---

## First Time Setup

1. Clone the repo onto your server:
   ```bash
   git clone <your-repo-url> ~/homelab
   cd ~/homelab
   ```

2. Copy and edit the environment file:
   ```bash
   cp .env.example .env
   nano .env
   ```
   Fill in your actual `SERVER_IP` (e.g. `192.168.1.100`).

3. Make scripts executable and run the init script:
   ```bash
   chmod +x scripts/*.sh
   ./scripts/init.sh
   ```

4. Open **Portainer** at `https://IP:9443` and create an admin account. Do this within 5 minutes or the setup window closes.

5. Open **Nginx Proxy Manager** at `http://IP:81`.
   Default credentials: `admin@example.com` / `changeme` — change these immediately.

6. Open **AdGuard Home** at `http://IP:3000` and complete the setup wizard.

---

## Setting Up Local DNS (homelab domains)

After completing the AdGuard setup wizard:

1. In AdGuard, go to **Filters → DNS Rewrites**
2. Add a wildcard rewrite:
   - Domain: `*.homelab`
   - Answer: your server IP (e.g. `192.168.1.100`)
3. Go to your **home router** settings
4. Set the **Primary DNS** to your server IP
5. All devices on your network can now resolve `.homelab` domains

---

## Setting Up Nginx Proxy Manager

To add a proxy host for each service:

1. Go to `http://IP:81` → **Hosts** → **Proxy Hosts** → **Add Proxy Host**
2. Fill in:
   - **Domain Names**: `jellyfin.homelab`
   - **Scheme**: `http`
   - **Forward Hostname / IP**: `jellyfin` (use the container name — Docker DNS resolves it)
   - **Forward Port**: `8096`
3. Save, then repeat for each service using the container name and port from the services table above

---

## Media Pipeline (How Automation Works)

```
Movies:
  Radarr → Prowlarr → qBittorrent → /home/media/movies → Jellyfin (auto-scans)

TV Shows:
  Sonarr → Prowlarr → qBittorrent → /home/media/tvshows → Jellyfin (auto-scans)

Books:
  Readarr → Prowlarr → qBittorrent → /home/media/books → Kavita (auto-scans)

Audiobooks:
  Readarr → Prowlarr → qBittorrent → /home/media/audiobooks → Audiobookshelf (auto-scans)
```

> **Note:** FlareSolverr bypasses Cloudflare-protected indexers. Add it in Prowlarr under **Settings → Indexers → Add Proxy** with host `flaresolverr` and port `8191`.

---

## GitHub Actions Auto-Deploy

Push any change to `main` and GitHub Actions will:
1. SSH into your server
2. Run `git pull origin main`
3. Redeploy **only** the stacks whose `.yml` files changed
4. Skip redeploy if no stack files changed

### GitHub Secrets to Add

Go to your repo → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
|---|---|
| `SERVER_IP` | Your server's local IP (e.g. `192.168.1.100`) |
| `SERVER_USER` | Your Ubuntu username |
| `SERVER_SSH_KEY` | Full contents of your `~/.ssh/id_rsa` private key |

### Generate an SSH Key (if needed)

Run this on your server:

```bash
ssh-keygen -t rsa -b 4096 -C "github-actions"
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
cat ~/.ssh/id_rsa    # copy this entire output → paste as SERVER_SSH_KEY secret
```

> The homelab repo must be cloned at `~/homelab` on your server for the deploy workflow to find it.

---

## Adding a New Container

1. Add the service definition to the appropriate stack `.yml` file in `stacks/`
2. Add its config directory to `scripts/folders.sh`
3. Run `scripts/folders.sh` on the server to create the directory
4. Commit and push to `main`
5. GitHub Actions auto-redeploys only the changed stack

---

## Connecting Arr Apps to Each Other

After all containers are running, connect them through their web UIs using container names as hostnames (Docker's internal DNS handles resolution):

| From | To | Host | Port |
|---|---|---|---|
| Prowlarr | FlareSolverr | `flaresolverr` | `8191` |
| Radarr | qBittorrent | `qbittorrent` | `8080` |
| Sonarr | qBittorrent | `qbittorrent` | `8080` |
| Readarr | qBittorrent | `qbittorrent` | `8080` |
| Radarr / Sonarr / Readarr | Prowlarr | `prowlarr` | `9696` (use Prowlarr API key) |
