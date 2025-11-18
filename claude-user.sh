#!/usr/bin/env bash
###############################################################################
#  Bootstrap "claude-user" with near-root privileges + Docker access
#  Works on Debian/Ubuntu (sudo) and RHEL/Fedora (wheel)
#  ───────────────────────────────────────────────────────────────────────────
#  Run as:  sudo bash setup-claude-user.sh   OR   (become root first)
###############################################################################

set -euo pipefail

NODE_VERSION="22"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"

### 0) Quick safety backups
stamp=$(date +%s)
cp /etc/passwd  /etc/passwd.bak.$stamp
cp /etc/shadow  /etc/shadow.bak.$stamp
cp /etc/group   /etc/group.bak.$stamp

### 1) Detect the admin group for this distro
admin_group=$(grep -qEi 'ID_LIKE=.*rhel' /etc/os-release && echo wheel || echo sudo)

### 2) Create the user (and same-named primary group)
if id claude-user &>/dev/null; then
  echo "[info] claude-user already exists – skipping useradd"
else
  useradd -m -s /bin/bash claude-user
fi

# Remove login password (SSH keys recommended; delete this line to set one)
passwd -d claude-user || true

### 3) Ensure docker group exists (Docker CE does this, but cover fresh installs)
getent group docker &>/dev/null || groupadd docker

### 4) Add admin + docker + root group memberships
usermod -aG "$admin_group",docker,root claude-user

### 5) Password-less sudo drop-in
cat >/etc/sudoers.d/claude-user <<'EOF'
claude-user ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/claude-user

### 6) Prepare /opt/docker-aicode
mkdir -p /opt/docker-aicode
#Replace with github clone once we have repo
#scp -r root@192.168.12.147:/opt/docker-aicode/* /opt/docker-aicode/

###############################################################################
#  7) Install nvm + Node + Claude Code + Codex for ROOT
###############################################################################
echo
echo "=== Installing nvm + Node ${NODE_VERSION} + Claude Code + Codex for root ==="

export NVM_DIR="/root/.nvm"

if [ ! -s "${NVM_DIR}/nvm.sh" ]; then
  echo "[root] nvm not found, installing..."
  mkdir -p "$(dirname "$NVM_DIR")"
  curl -o- "${NVM_INSTALL_URL}" | bash
else
  echo "[root] nvm already installed, reusing existing installation."
fi

# Load nvm into current shell session
# shellcheck source=/dev/null
. "${NVM_DIR}/nvm.sh"

# Install / use Node
nvm install "${NODE_VERSION}"
nvm use "${NODE_VERSION}"

# Verify Node.js and npm versions
node -v
nvm current
npm -v

# Install Claude Code + Codex globally for root
npm install -g @anthropic-ai/claude-code @openai/codex

###############################################################################
#  8) Install nvm + Node + Claude Code + Codex for claude-user
###############################################################################
echo
echo "=== Installing nvm + Node ${NODE_VERSION} + Claude Code + Codex for claude-user ==="

su -l claude-user <<'EOSU'
set -euo pipefail

NODE_VERSION="22"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"

export NVM_DIR="$HOME/.nvm"

if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  echo "[claude-user] nvm not found, installing..."
  mkdir -p "$(dirname "$NVM_DIR")"
  curl -o- "$NVM_INSTALL_URL" | bash
else
  echo "[claude-user] nvm already installed, reusing existing installation."
fi

# Load nvm
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"

# Install / use Node
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"

# Verify Node.js and npm versions
node -v
nvm current
npm -v

# Install Claude Code + Codex globally for claude-user
npm install -g @anthropic-ai/claude-code @openai/codex
EOSU

echo
echo "✅ Finished!"
echo "   User setup complete and tools installed for both root and claude-user."
echo "   Verify as claude-user with:"
echo "     su -l claude-user"
echo "     id"
echo "     docker info | head -5"
echo "     node -v && npm -v"
echo "     which claude && which codex || which npx"
