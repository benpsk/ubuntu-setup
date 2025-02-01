#!/usr/bin/env bash

set -e

## Reset
RESET='\033[0m'

## Regular Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

## Background
ON_GREEN='\033[42m'
ON_YELLOW='\033[43m'
ON_CYAN='\033[46m'

exit_message() {
  echo
  echo -e "${ON_GREEN}Goodbye, See you next time!${RESET}"
  echo
}

skip_message() {
  echo -e "${ON_YELLOW}Skipping... $1 installation!${RESET}"
}

install_message() {
  echo
  echo -e "${ON_CYAN}Installing... $1${RESET}"
  echo
}

welcome_message() {
  echo -e "$(
    cat <<-EOM
			${ON_GREEN}

			***********************************

			Welcome to my ubuntu setup script!

			***********************************

			${RESET}

		EOM
  )"
  echo
  echo -ne "${YELLOW}Press any key to start! : ${RESET}"
  read begin
  echo
}

goodbye_message() {
  echo -e "$(
    cat <<-EOM
			${ON_GREEN}

			***********************************

			Thank you for using me!

			***********************************

			${RESET}
		EOM
  )"
}

ask() {
  if [ "$2" = "error" ]; then
    echo >&2
    echo -e "${RED}Infor: please choose (y/n/q).${RESET}" >&2
  fi
  echo -ne "${GREEN}Install $1? (y/n/q): ${RESET}" >&2 # Send prompt to stderr
  read -r response
  answer=$(echo "$response" | tr "[:upper:]" "[:lower:]")

  if [ "$answer" = "q" ]; then
    exit_message
    exit 0
  fi

  if [[ "$answer" = "y" || "$answer" = "n" ]]; then
    echo "$answer"
  else
    ask $1 "error"
  fi
}

zsh=$(ask "zsh")
oh_my_zsh=$(ask "oh_my_zsh")
fonts=$(ask "fonts (Hasklig & Github monaspace)")
vim=$(ask "vim")
neovim=$(ask "neovim")
lazyvim=$(ask "lazyvim")
lazygit=$(ask "lazygit")
php=$(ask "php")
composer=$(ask "composer")
laravel_installer=$(ask "laravel installer")
mariadb=$(ask "mariadb")
postgresql=$(ask "postgresql")
nginx=$(ask "nginx")
nodejs=$(ask "nodejs")
vscode=$(ask "vscode")
tableplus=$(ask "tableplus (lightweight sql editor)")
dbeaver=$(ask "dbeaver (sql editor)")
shortcut=$(ask "shortcut (~/.zshrc)")

pre_install() {
  ## system update and upgrade
  sudo apt update
  sudo apt upgrade -y
  sudo apt-get install git
}

pre_install

if [ "$zsh" = "y" ]; then
  install_message "zsh"
  ## install zsh
  sudo apt install zsh
  echo zsh --version
  sudo chsh -s $(which zsh)
  echo $SHELL
  $SHELL --version
else
  skip_message "php"
fi

if [[ "$zsh" = "y" && "$oh_my_zsh" = "y" ]]; then
  install_message "oh my zsh"
  ## install oh my zsh
  sudo apt install curl
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  skip_message "oh my zsh"
fi

if [ "$fonts" = "y" ]; then
  install_message "fonts"
  ## install fonts
  https://github.com/githubnext/monaspace.git
  bash util/install_linux.sh
  LATEST_URL=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep "browser_download_url.*Hasklig.zip" | cut -d '"' -f 4)
  curl -LO "$LATEST_URL"
  mkdir -p ~/.local/share/fonts/Hasklig
  unzip Hasklig.zip -d ~/.local/share/fonts/Hasklig
  rm Hasklig.zip
else
  skip_message "fonts"
fi

if [ "$vim" = "y" ]; then
  install_message "vim"
  ## install vim
  sudo apt install vim
else
  skip_message "vim"
fi

if [[ "$vim" = "y" && "$neovim" = "y" ]]; then
  install_message "neovim"
  ## install neovim [lazyvim required neovim > v9.0, ubuntu 22.04 support neovim v9.5. so, we are good.]
  sudo apt install neovim
else
  skip_message "neovim"
fi

if [[ "$vim" = "y" && "$neovim" = "y" && "$lazyvim" = "y" ]]; then
  install_message "lazyvim"
  ## install lazyvim
  ### make backup
  ### required
  mv ~/.config/nvim{,.bak}
  ### optional but recommended
  mv ~/.local/share/nvim{,.bak}
  mv ~/.local/state/nvim{,.bak}
  mv ~/.cache/nvim{,.bak}
  ### clone
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git
else
  skip_message "lazyvim"
fi

if [ "$lazygit" = "y" ]; then
  install_message "lazygit"
  ## install lazygit
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit -D -t /usr/local/bin/
  lazygit --version
else
  skip_message "lazygit"
fi

if [ "$php" = "y" ]; then
  install_message "php"
  ## install onjdre php
  sudo add-apt-repository ppa:ondrej/php
  sudo apt update
  sudo apt install php8.4 php8.4-fpm php8.4-opcache php8.4-mysql php8.4-pgsql php8.4-common php8.4-mbstring php8.4-curl php8.4-soap php8.4-zip php8.4-gd php8.4-xml php8.4-intl php8.4-imagick
else
  skip_message "php"
fi

if [[ "$composer" = "y" && "$php" = "y" ]]; then
  install_message "composer"
  ## install composer
  EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
  if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    >&2 echo 'ERROR: Invalid installer checksum'
    rm composer-setup.php
  fi
  php composer-setup.php --quiet
  RESULT=$?
  rm composer-setup.php
  echo $RESULT
else
  skip_message "composer"
fi

if [[ "$laravel_installer" = "y" && "$php" = "y" && "$composer" = "y" ]]; then
  install_message "laravel installer"
  ## install laravel installer
  composer global require laravel/installer
else
  skip_message "laravel installer"
fi

if [ "$mariadb" = "y" ]; then
  install_message "mariadb"
  ## install mariadb
  sudo apt-get install apt-transport-https curl jq
  sudo mkdir -p /etc/apt/keyrings
  sudo curl -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'
  # get mariadb versions
  versions=$(curl -s "https://downloads.mariadb.org/rest-api/mariadb/")
  # use jq to extract the latest stable and long term support id
  latest_lts_release=$(echo "$versions" | jq -r '.major_releases[] | select(.release_status == "Stable" and .release_support_type == "Long Term Support") | .release_id' | head -n 1)
  echo "
# MariaDB $latest_lts_release repository list - created 2025-01-31 16:23 UTC
# https://mariadb.org/download/
X-Repolib-Name: MariaDB
Types: deb
# deb.mariadb.org is a dynamic mirror if your preferred mirror goes offline. See https://mariadb.org/mirrorbits/ for details.
# URIs: https://deb.mariadb.org/$latest_lts_release/ubuntu
URIs: https://mirror.kku.ac.th/mariadb/repo/$latest_lts_release/ubuntu
Suites: $(lsb_release -cs)
Components: main main/debug
Signed-By: /etc/apt/keyrings/mariadb-keyring.pgp
" | sudo tee etc/apt/sources.list.d/mariadb.sources
  sudo apt-get update
  sudo apt-get install mariadb-server -y
  sudo systemctl disable mariadb
else
  skip_message "mariadb"
fi

if [ "$postgresql" = "y" ]; then
  install_message "postgresql"
  ## install postgresql [install postgresql supported version depend on ubuntu version]
  sudo apt install postgresql -y
  sudo systemctl disable postgresql
else
  skip_message "postgresql"
fi

if [ "$nginx" = "y" ]; then
  install_message "nginx"
  ## install nginx
  sudo apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring -y
  curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor |
    sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
  gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" |
    sudo tee /etc/apt/sources.list.d/nginx.list
  sudo apt update
  sudo apt install nginx -y
else
  skip_message "nginx"
fi

if [ "$nodejs" = "y" ]; then
  install_message "nodejs"
  ## install nodejs [using nvm package manager]
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  nvm install 22
  node -v
  nvm current
  npm -v
else
  skip_message "nodejs"
fi

if [ "$vscode" = "y" ]; then
  install_message "vscode"
  ## install vscode
  curl -L -o vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
  sudo apt install ./vscode.db -y
  rm vscode.deb
else
  skip_message "vscode"
fi

if [ "$tableplus" = "y" ]; then
  install_message "tableplus"
  ## install tableplus
  sudo apt install software-properties-common
  # Add TablePlus gpg key
  wget -qO - https://deb.tableplus.com/apt.tableplus.com.gpg.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/tableplus-archive.gpg >/dev/null
  # Add TablePlus repo
  arch=$(dpkg --print-architecture)
  major=$(lsb_release -rs | cut -d. -f1)
  if [ "$arch" = "amd64" ]; then
    sudo add-apt-repository "deb [arch=amd64] https://deb.tableplus.com/debian/$major tableplus main"
  fi
  if [ "$arch" = "arm64" ]; then
    sudo add-apt-repository "deb [arch=arm64] https://deb.tableplus.com/debian/$major-arm tableplus main"
  fi
  if [[ "$arch" = "amd64" || "$arch" = "arm64" ]]; then
    # Install
    sudo apt update
    sudo apt install tableplus
  fi
else
  skip_message "tableplus"
fi

if [ "$dbeaver" = "y" ]; then
  install_message "dbeaver"
  ## install dbeaver
  curl -L -o dbeaver.deb "https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb"
  sudo apt install ./dbeaver.deb -y
  rm dbeaver.deb
else
  skip_message "dbeaver"
fi

if [ "$shortcut" = "y" && "$zsh" = "y" ]; then
  install_message "shortcut"
  echo '
alias c="clear"
alias vim="nvim"
alias phps="phpstorm ."
alias ws="webstorm ."
alias vs="code ."
# alias p72="/opt/homebrew/opt/php@7.2/bin/php"

# laravel alias
alias pa="php artisan"
alias t="php artisan test"
alias pest="./vendor/bin/pest"
alias pestp="./vendor/bin/pest --profile"

# sublime text 
# alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"

# pnpm alias
alias pn=pnpm

# git alias
alias gss="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push origin"

alias q="exit"
' | tee -a ~/.zshrc
  source ~/.zshrc
else
  skip_message "shortcut"
fi

goodbye_message
