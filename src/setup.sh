#!/bin/bash

create_symlink() {
    local source=$1
    local destination=$2

    if [ -e "$destination" ] || [ -L "$destination" ]; then
        echo "Destination $destination already exists. Removing it."
        rm -rf "$destination"
    fi

    if [ -d "$source" ]; then
        ln -s "$source" "$destination"
    else
        ln -sf "$source" "$destination"
    fi
    echo "Created symlink: $destination -> $source"
}

check_required_programs() {
    for program in tmux zsh; do
        if ! command -v $program &> /dev/null; then
            echo "Error: $program is not installed. Please ensure it's in /boot/extra as a .txz package."
            exit 1
        fi
    done
    echo "All required programs are installed."
}

check_required_files() {
    if [ ! -d "/boot/config/extra/.oh-my-zsh" ] || [ ! -f "/boot/config/extra/.zshrc" ]; then
        echo "Error: Required files not found in /boot/config/extra"
        exit 1
    fi
}

ensure_prerequisites() {
    check_required_programs
    check_required_files
}

setup() {
    echo "Setting up Zsh for root"

    create_symlink "/boot/config/extra/.oh-my-zsh" "/root/.oh-my-zsh"
    create_symlink "/boot/config/extra/.zshrc" "/root/.zshrc"
    create_symlink "/boot/config/extra/.zsh_history" "/root/.zsh_history"

    if ! grep -q "/bin/zsh" /etc/passwd | grep "root"; then
        if ! chsh -s /bin/zsh root; then
            echo "Failed to change shell for root"
        else
            echo "Successfully changed shell to Zsh for root"
        fi
    else
        echo "Shell is already set to Zsh for root"
    fi
}

set_zsh_for_webterminal_ttyd() {
    local openterminal_path="/usr/local/emhttp/plugins/dynamix/include/OpenTerminal.php"
    
    if [ -f "$openterminal_path" ]; then
        echo "Updating OpenTerminal.php to use Zsh..."
        sed -i '/ttyd-exec.*bash --login/s/bash/zsh/' "$openterminal_path"
        
        if grep -q 'ttyd-exec.*zsh --login' "$openterminal_path"; then
            echo "OpenTerminal.php updated successfully."
        else
            echo "Warning: Failed to update OpenTerminal.php. Please check the file manually."
        fi
    else
        echo "Warning: OpenTerminal.php not found at $openterminal_path"
    fi
}

main() {
    ensure_prerequisites
    setup
    set_zsh_for_webterminal_ttyd
    echo "Zsh, Oh My Zsh setup, and WebTerminal-ttyd update completed successfully."
    
    # Zum Neustarten von ttyd:
    # pidof ttyd | xargs -r kill && ttyd -p 7681 -i lo zsh &
}

main
