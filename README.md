# polish_lxc

Quick bootstrap script for fresh Debian / Ubuntu LXC containers in Proxmox.

## Features
- Installs `locales`, `tzdata`, and `bash-completion`
- Generates `pl_PL.UTF-8` and `en_US.UTF-8` locales and sets `LANG=pl_PL.UTF-8`
- Sets timezone to `Europe/Warsaw`
- Interactively creates a new user (`adduser`) and optionally grants `sudo` access
- Enables full terminal colors (`PS1`, `ls`, `dir`, `grep`, `GCC`, `diff`, `ip`):
  - green prompt for the new user
  - red prompt for `root` (with backup at `/root/.bashrc.bak`)

## Usage (inside LXC container as `root`)

```bash
apt update && apt install -y curl
curl -fsSL https://raw.githubusercontent.com/TranceEX/polish_lxc/main/setup.sh -o setup.sh
chmod +x setup.sh
./setup.sh
```

## After the script finishes, reload your current shell session:

```bash
exec bash
```
