#!/usr/bin/env bash
###############################################################################
#  Bootstrap "claude-user" with near-root privileges + Docker access
#  Works on Debian/Ubuntu (sudo) and RHEL/Fedora (wheel)
#  ───────────────────────────────────────────────────────────────────────────
#  Run as:  sudo bash setup-claude-user.sh   OR   (become root first)
###############################################################################

set -euo pipefail

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
passwd -d claude-user

### 3) Ensure docker group exists (Docker CE does this, but cover fresh installs)
getent group docker &>/dev/null || groupadd docker

### 4) Add admin + docker + root group memberships
usermod -aG "$admin_group",docker,root claude-user

### 5) Password-less sudo drop-in
cat >/etc/sudoers.d/claude-user <<'EOF'
claude-user ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/claude-user

echo -e "\n✅  Finished!  Log out and back in (or run: exec su -l claude-user)."
echo "   Verify with:  id   |   sudo -l   |   docker info | head -5"

#Replace with github clone once we have repo
mkdir -p /opt/docker-aicode

# 2) Recursively copy everything from the remote host’s /opt/docker-aicode
#    to the identical path on your local system.
scp -r root@192.168.12.147:/opt/docker-aicode/* /opt/docker-aicode/

# Install nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Load nvm into current shell session
\. "$HOME/.nvm/nvm.sh"

# Install Node.js version 22
nvm install 22

# Verify Node.js and npm versions
node -v
nvm current
npm -v

# Install Claude globally
npm install -g @anthropic-ai/claude-code
