#!/usr/bin/env bash
set -euo pipefail

echo "Creating media directories..."
mkdir -p /home/media/movies
mkdir -p /home/media/tvshows
mkdir -p /home/media/audiobooks
mkdir -p /home/media/books
mkdir -p /home/media/downloads/complete
mkdir -p /home/media/downloads/incomplete

echo "Creating Docker config directories..."
mkdir -p /home/docker/traefik
mkdir -p /home/docker/pihole/etc-pihole
mkdir -p /home/docker/pihole/etc-dnsmasq.d
mkdir -p /home/docker/audiobookshelf
mkdir -p /home/docker/kavita
mkdir -p /home/docker/qbittorrent
mkdir -p /home/docker/prowlarr
mkdir -p /home/docker/radarr
mkdir -p /home/docker/sonarr
mkdir -p /home/docker/lazylibrarian
mkdir -p /home/docker/jellyfin/config
mkdir -p /home/docker/jellyfin/cache
mkdir -p /home/docker/homepage

echo "Setting permissions..."
sudo chown -R 1000:1000 /home/media
sudo chown -R 1000:1000 /home/docker

echo "✅ All folders created successfully"
