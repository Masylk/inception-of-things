#!/usr/bin/env bash
set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${YELLOW}==> Checking Docker installation...${NC}"

# Determine appropriate release name for Docker
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
DOCKER_CODENAME="$CODENAME"

# Docker does NOT support forky, trixie, sid → use bookworm
if [[ "$CODENAME" =~ (forky|trixie|sid|testing|unstable) ]]; then
    DOCKER_CODENAME="bookworm"
fi

# -----------------------------
# 1. Install Docker (idempotent)
# -----------------------------
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${YELLOW}Docker not found. Installing Docker...${NC}"

    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Add GPG key once
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | \
            sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    fi

    # Add repo only if missing
    if ! grep -q "download.docker.com" /etc/apt/sources.list.d/docker.list 2>/dev/null; then
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
          https://download.docker.com/linux/debian $DOCKER_CODENAME stable" \
          | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    sudo apt-get update -y

    sudo apt-get install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    sudo usermod -aG docker "$USER"

    echo -e "${GREEN}Docker installed successfully.${NC}"
else
    echo -e "${GREEN}Docker already installed. Skipping.${NC}"
fi

# -----------------------------
# 2. Install k3d (idempotent)
# -----------------------------
echo -e "${YELLOW}==> Checking k3d installation...${NC}"

if ! command -v k3d >/dev/null 2>&1; then
    echo -e "${YELLOW}k3d not found. Installing...${NC}"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo -e "${GREEN}k3d installed successfully.${NC}"
else
    echo -e "${GREEN}k3d already installed. Skipping.${NC}"
fi

echo -e "${GREEN}✔ All done!${NC}"
echo -e "${YELLOW}👉 Logout/login may be required for Docker group permissions.${NC}"
