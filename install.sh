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

# ---------- System Packages (apt) ---------- #
# Keep apt for system-level deps only; dev tooling goes through brew
echo "[*] Installing system packages..."
sudo apt-get update
sudo apt-get install -y \
  curl \
  wget \
  git \
  zip \
  htop \
  xclip \
  zsh \
  build-essential  # required by brew

# ---------- Homebrew ---------- #
echo "[*] Installing Homebrew..."
if ! command -v brew &>/dev/null; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# ---------- Dev Tooling (brew) ---------- #
echo "[*] Installing dev tools via brew..."
brew install \
  fzf \
  bat \
  ripgrep \
  fnm \
  tmux \
  derailed/k9s/k9s

# fzf shell integration
$(brew --prefix)/opt/fzf/install --all --no-update-rc

# ---------- Node.js (via fnm) ---------- #
echo "[*] Installing Node.js 20 via fnm..."
eval "$(fnm env)"
fnm install 20
fnm default 20

# ---------- tmux config ---------- #
echo "[*] Writing ~/.tmux.conf..."
cat << 'EOF' > "$HOME/.tmux.conf"
# ---------- Core ---------- #
set -g default-terminal "screen-256color"
set -g history-limit 10000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# ---------- Mouse ---------- #
set -g mouse on

# ---------- Splits ---------- #
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"

# ---------- Pane Navigation ---------- #
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# ---------- Window Navigation ---------- #
bind -n S-Left previous-window
bind -n S-Right next-window

# ---------- Copy Mode ---------- #
setw -g mode-keys vi
bind Enter copy-mode
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel

# ---------- Quality of Life ---------- #
set -s escape-time 0
set -g focus-events on
bind r source-file ~/.tmux.conf \; display "Config reloaded"

# ---------- Status Bar ---------- #
set -g status-position bottom
set -g status-interval 5
set -g status-left "#[fg=green]#S "
set -g status-right "#[fg=yellow]%H:%M "
set -g status-right-length 20
set -g window-status-current-format "#[fg=white,bold]#I:#W"
set -g window-status-format "#[fg=colour244]#I:#W"
EOF

# ---------- Shell Setup ---------- #
echo "[*] Setting up Zsh..."
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

sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC_PATH"
sed -i '/^plugins=/c\plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' "$ZSHRC_PATH"

# ---------- .zshrc Additions (idempotent) ---------- #

# p10k instant prompt — must be at very top to avoid console output warning
if ! grep -q 'POWERLEVEL9K_INSTANT_PROMPT' "$ZSHRC_PATH"; then
  echo "[*] Prepending p10k instant prompt fix..."
  TMPFILE=$(mktemp)
  echo 'typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet' | cat - "$ZSHRC_PATH" > "$TMPFILE"
  mv "$TMPFILE" "$ZSHRC_PATH"
fi

# Homebrew
if ! grep -q 'brew shellenv' "$ZSHRC_PATH"; then
  cat << 'EOF' >> "$ZSHRC_PATH"

# Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
EOF
fi

# Brew auto-update (weekly)
if ! grep -q 'brew update' "$ZSHRC_PATH"; then
  cat << 'EOF' >> "$ZSHRC_PATH"

# Brew auto-update (weekly)
if [[ $(find "$(brew --prefix)/Library/Taps/homebrew/homebrew-core" -maxdepth 0 -mtime +7 2>/dev/null) ]]; then
  echo "[brew] Running weekly update..."
  brew update && brew upgrade && brew cleanup
fi
EOF
fi

# fnm
if ! grep -q 'fnm env' "$ZSHRC_PATH"; then
  cat << 'EOF' >> "$ZSHRC_PATH"

# fnm (Node version manager)
eval "$(fnm env --use-on-cd)"
EOF
fi

# fzf keybindings
if ! grep -q 'fzf.zsh' "$ZSHRC_PATH"; then
  cat << 'EOF' >> "$ZSHRC_PATH"

# fzf
bindkey -s '^F' '$(fzf --query "" --preview "bat --style=numbers --color=always {} || cat {}" --bind "enter:accept")\n'
export FZF_CTRL_R_OPTS="--reverse --no-sort --exact"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
EOF
fi

# p10k config
if ! grep -q 'p10k.zsh' "$ZSHRC_PATH"; then
  cat << 'EOF' >> "$ZSHRC_PATH"

# p10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
fi

# Tab title
if ! grep -q 'set-tab-title' "$ZSHRC_PATH"; then
  cat << 'EOF' >> "$ZSHRC_PATH"

# Tab title
function set-tab-title {
  print -Pn "\e]0;%n@%m: %~\a"
}
precmd_functions+=(set-tab-title)
EOF
fi

# ---------- Unattended Upgrades (apt) ---------- #
echo "[*] Installing unattended-upgrades..."
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

DISTRO_ID=$(lsb_release -si)
DISTRO_CODENAME=$(lsb_release -sc)

sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<EOF
Unattended-Upgrade::Allowed-Origins {
        "${DISTRO_ID}:${DISTRO_CODENAME}";
        "${DISTRO_ID}:${DISTRO_CODENAME}-security";
        "${DISTRO_ID}ESMApps:${DISTRO_CODENAME}-apps-security";
        "${DISTRO_ID}ESM:${DISTRO_CODENAME}-infra-security";
        "${DISTRO_ID}:${DISTRO_CODENAME}-updates";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::DevRelease "auto";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

sudo unattended-upgrade --dry-run --debug > /dev/null

# ---------- Done ---------- #
echo "[*] Bootstrap complete. Launch a new shell or run 'zsh' to use your configuration."
echo "    Run 'tmux' manually when you need it."
