#!/bin/bash

set -e

# ---------- CONFIG ---------- #
ZSH_CUSTOM_DIR="$HOME/.oh-my-zsh/custom"
ZSHRC_PATH="$HOME/.zshrc"

# ---------- Prep /git ---------- #
echo "[*] Ensuring /git directory is present and owned by user..."
sudo mkdir -p /git
sudo chown "$USER:$USER" /git
sudo mkdir -p /git/shellkit
sudo chown "$USER:$USER" /git/shellkit

# ---------- Tooling ---------- #
echo "[*] Installing basic tools..."
sudo apt-get update
sudo apt-get install -y curl xclip ripgrep zsh wget bat

# fzf
if [ ! -d "$HOME/.fzf" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --all
fi

# ---------- Node.js ---------- #
echo "[*] Installing Node.js 20..."
wget https://nodejs.org/dist/v20.14.0/node-v20.14.0-linux-x64.tar.xz -O /tmp/node.tar.xz
sudo tar -xf /tmp/node.tar.xz --one-top-level=/usr/local -C /usr/local/

# ---------- Shell Setup ---------- #
echo "[*] Setting up Zsh..."
sudo apt-get install -y zsh
chsh -s $(which zsh)

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "[*] Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
fi

# powerlevel10k
if [ ! -d "$ZSH_CUSTOM_DIR/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
fi

# Replace default ZSH_THEME in .zshrc
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC_PATH"


# Inject custom .zshrc additions
cat << 'EOF' >> "$ZSHRC_PATH"

alias bat="batcat"

# ⌥ Ctrl+F — Fuzzy File Finder (current dir)
bindkey -s '^F' '$(fzf --query "" --preview "bat --style=numbers --color=always {} || cat {}" --bind "enter:accept")\n'

# 🔁 Ctrl+R — Fuzzy history search (all sessions)
export FZF_CTRL_R_OPTS="--reverse --no-sort --exact"

# Load fzf's keybindings (assumes fzf is installed via Git or package manager)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

EOF

# ---------- Done ---------- #
echo "[*] Bootstrap complete. Launch a new shell or run 'zsh' to use your configuration."
