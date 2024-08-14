#!/bin/bash

PLUGIN_DIR="/boot/config/plugins/OhMyZSH"
DEFAULT_THEME="PureUnraid"
DEFAULT_PLUGINS="git copypath copyfile copybuffer dirhistory zsh-autosuggestions zsh-syntax-highlighting sudo history tmux"

prepare_slackware_packages() {
    sh slack_pkg_mgr.sh
}

install_oh_my_zsh() {
    export RUNZSH=no
    export KEEP_ZSHRC=yes
    ZSH="$PLUGIN_DIR/.oh-my-zsh" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "Oh My Zsh installed"
}

create_theme() {
    cat << "EOF" > "$PLUGIN_DIR/.oh-my-zsh/custom/themes/PureUnraid.zsh-theme"
local return_code="%(?..%F{red}%? %f)"

PROMPT='%F{208}{ %c } %F{green}$(git rev-parse --abbrev-ref HEAD 2> /dev/null || echo "")%f %F{yellow}%(!.⚡.»)%f '

PROMPT2='%F{yellow}\\ %f'

RPS1='%F{white}%~%f ${return_code}'

ZSH_THEME_GIT_PROMPT_PREFIX="%f:: %F{cyan}("
ZSH_THEME_GIT_PROMPT_SUFFIX=")%f "
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="%F{red}*%F{cyan}"
EOF
    echo "PureUnraid theme created"
}

install_plugins() {
    git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    echo "zsh-autosuggestions plugin installed"
    
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    echo "zsh-syntax-highlighting plugin installed"
}

rewrite_zshrc() {
    cat << EOF > "$PLUGIN_DIR/.zshrc"
export ZSH="/root/.oh-my-zsh"
ZSH_THEME="$DEFAULT_THEME"
ENABLE_CORRECTION="true"
CORRECT_IGNORE="[_|.]*"
plugins=($DEFAULT_PLUGINS)
zstyle ':omz:update' mode auto
source \$ZSH/oh-my-zsh.sh
EOF
    echo ".zshrc rewritten"
}

create_history_file() {
    touch "$PLUGIN_DIR/.zsh_history"
    echo "Empty .zsh_history file created"
}

set_permissions() {
    chmod 755 "$PLUGIN_DIR" "$PLUGIN_DIR/.oh-my-zsh"
    chmod 755 "$PLUGIN_DIR/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "$PLUGIN_DIR/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    chmod 644 "$PLUGIN_DIR/.zshrc" "$PLUGIN_DIR/.oh-my-zsh/custom/themes/PureUnraid.zsh-theme"
    chmod 600 "$PLUGIN_DIR/.zsh_history"
    echo "Permissions set for all files and newly installed plugins"
}

restart_ttyd() {
    pidof ttyd | xargs -r kill && ttyd -p 7681 -i lo zsh &
    echo "ttyd restarted"
}

main() {
    prepare_slackware_packages
    install_oh_my_zsh
    create_theme
    install_plugins
    rewrite_zshrc
    create_history_file
    set_permissions
    restart_ttyd
    echo "Installation completed. Please run the start_ohmyzsh.sh script on the next system startup."
}

main
