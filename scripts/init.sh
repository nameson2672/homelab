#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting Homelab Setup..."

# 1. Check Docker
if ! command -v docker &>/dev/null; then
  echo "❌ Docker is not installed. Please install Docker before running this script."
  exit 1
fi
echo "✅ Docker found: $(docker --version)"

# 2. Create folders
echo ""
echo "--- Creating directory structure ---"
bash "$SCRIPT_DIR/folders.sh"

# 3. Create Docker network
echo ""
echo "--- Setting up Docker network ---"
docker network create bookstack 2>/dev/null || echo "Network 'bookstack' already exists"

# 4. Copy .env if missing
echo ""
echo "--- Checking .env ---"
if [ ! -f "$REPO_DIR/.env" ]; then
  cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
  echo "✅ Created .env from .env.example — edit it with your SERVER_IP before continuing."
else
  echo ".env already exists, skipping."
fi

# 5. Deploy stacks
echo ""
echo "--- Deploying network stack (Traefik + Pi-hole) ---"
docker compose -f "$REPO_DIR/stacks/network.yml" up -d

echo ""
echo "--- Deploying media stack ---"
docker compose -f "$REPO_DIR/stacks/media.yml" up -d

echo ""
echo "--- Deploying downloaders stack ---"
docker compose -f "$REPO_DIR/stacks/downloaders.yml" up -d

echo ""
echo "--- Deploying entertainment stack ---"
docker compose -f "$REPO_DIR/stacks/entertainment.yml" up -d

# 6. Auto-detect server IP
IP=$(hostname -I | awk '{print $1}')

# 7. Print services table
echo ""
echo "==========================================="
echo " HOMELAB SERVICES"
echo "==========================================="
printf " %-22s %s\n" "Traefik Dashboard"  "http://${IP}:8080  → traefik.homelab"
printf " %-22s %s\n" "Pi-hole"            "http://${IP}:8181  → pihole.homelab"
printf " %-22s %s\n" "Jellyfin"           "http://${IP}:8096  → jellyfin.homelab"
printf " %-22s %s\n" "Audiobookshelf"     "http://${IP}:13378 → audiobookshelf.homelab"
printf " %-22s %s\n" "Kavita"             "http://${IP}:5000  → kavita.homelab"
printf " %-22s %s\n" "qBittorrent"        "http://${IP}:8080  → qbittorrent.homelab"
printf " %-22s %s\n" "Prowlarr"           "http://${IP}:9696  → prowlarr.homelab"
printf " %-22s %s\n" "Radarr"             "http://${IP}:7878  → radarr.homelab"
printf " %-22s %s\n" "Sonarr"             "http://${IP}:8989  → sonarr.homelab"
printf " %-22s %s\n" "Readarr"            "http://${IP}:8787  → readarr.homelab"
printf " %-22s %s\n" "LazyLibrarian"      "http://${IP}:5299  → lazylibrarian.homelab"
printf " %-22s %s\n" "FlareSolverr"       "http://${IP}:8191"
echo "==========================================="
echo " After Pi-hole setup, set your router's"
echo " DNS to ${IP} and add a wildcard DNS"
echo " record: *.homelab → ${IP}"
echo " Then all .homelab domains route via Traefik"
echo "==========================================="
