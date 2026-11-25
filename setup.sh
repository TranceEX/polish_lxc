#!/usr/bin/env bash
set -euo pipefail

# 1. Check root privileges
if [[ "$(id -u)" -ne 0 ]]; then
    echo "Error: Please run this script as root!" >&2
    exit 1
fi

# 2. Prompt for and validate new username
while true; do
    read -rp "Enter new username: " USERNAME
    if [[ -z "$USERNAME" ]]; then
        echo "Username cannot be empty."
        continue
    fi
    if ! [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo "Invalid username (use lowercase letters, digits, '-' or '_', starting with a letter or '_')."
        continue
    fi
    if id "$USERNAME" &>/dev/null; then
        echo "User '$USERNAME' already exists. Please choose another name."
        continue
    fi
    break
done

read -rp "Add user '$USERNAME' to the sudo group? [y/N]: " ADD_SUDO

echo ""
echo "==> [1/5] Installing required packages (locales, tzdata, bash-completion)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y locales tzdata bash-completion

echo ""
echo "==> [2/5] Configuring locales (pl_PL.UTF-8, en_US.UTF-8)..."
sed -i -E 's/^# *(pl_PL\.UTF-8)/\1/' /etc/locale.gen
sed -i -E 's/^# *(en_US\.UTF-8)/\1/' /etc/locale.gen
grep -q '^pl_PL\.UTF-8' /etc/locale.gen || echo 'pl_PL.UTF-8 UTF-8' >> /etc/locale.gen
grep -q '^en_US\.UTF-8' /etc/locale.gen || echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
update-locale LANG=pl_PL.UTF-8

echo ""
echo "==> [3/5] Setting timezone (Europe/Warsaw)..."
if command -v timedatectl &>/dev/null && timedatectl set-timezone Europe/Warsaw 2>/dev/null; then
    true
else
    ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata
fi
echo "Current system time: $(date)"

echo ""
echo "==> [4/5] Creating user '$USERNAME'..."
adduser "$USERNAME"

if [[ "$ADD_SUDO" =~ ^[yY]([eE][sS])?$ ]]; then
    apt-get install -y sudo
    usermod -aG sudo "$USERNAME"
    echo "User '$USERNAME' added to the sudo group."
fi

echo ""
echo "==> [5/5] Enabling terminal colors for '$USERNAME' and 'root'..."
USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"
USER_BASHRC="${USER_HOME}/.bashrc"

if [[ -f "$USER_BASHRC" ]]; then
    sed -i -E \
        -e 's/^#force_color_prompt=yes/force_color_prompt=yes/' \
        -e 's/^([[:space:]]*)#(alias (dir|vdir|grep|fgrep|egrep)=)/\1\2/' \
        -e 's/^#(export GCC_COLORS=)/\1/' \
        "$USER_BASHRC"

    if ! grep -q "# Extra colors and aliases" "$USER_BASHRC"; then
        cat << 'EOF' >> "$USER_BASHRC"

# Extra colors and aliases
alias diff='diff --color=auto'
alias ip='ip -color=auto'
alias ll='ls -l'
alias la='ls -A'
EOF
    fi
    chown "${USERNAME}:${USERNAME}" "$USER_BASHRC"

    # Configure root .bashrc (backup original + set red prompt)
    if [[ -f /root/.bashrc && ! -f /root/.bashrc.bak ]]; then
        cp /root/.bashrc /root/.bashrc.bak
    fi
    cp "$USER_BASHRC" /root/.bashrc
    sed -i '/PS1=.*01;32m/s/01;32m/01;31m/' /root/.bashrc
    chown root:root /root/.bashrc
else
    echo "Warning: $USER_BASHRC not found, skipping color configuration." >&2
fi

echo ""
echo "============================================================"
echo " Setup complete!"
echo " - Timezone : Europe/Warsaw ($(date))"
echo " - Locales  : pl_PL.UTF-8 and en_US.UTF-8 (LANG=pl_PL.UTF-8)"
echo " - User     : $USERNAME"
echo " - Colors   : enabled for '$USERNAME' (green) and 'root' (red)"
echo ""
echo " To apply changes to your current shell session, run:"
echo "   exec bash"
echo "============================================================"
