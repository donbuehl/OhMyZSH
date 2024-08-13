#!/bin/bash

SCRIPT_DIR="/boot/config/plugins/OhMyZSH"
GO_FILE="/boot/config/go"

execute_script() {
    local script="$1"
    if [ -f "$SCRIPT_DIR/$script" ]; then
        echo "Executing $script..."
        chmod +x "$SCRIPT_DIR/$script"
        "$SCRIPT_DIR/$script"
    else
        echo "Error: $script not found."
        exit 1
    fi
}

update_go_file() {
    local updated=false
    local temp_file=$(mktemp)

    grep -v "$SCRIPT_DIR" "$GO_FILE" > "$temp_file"
    
    if ! cmp -s "$GO_FILE" "$temp_file"; then
        updated=true
    fi

    if ! grep -qxF "$SCRIPT_DIR/setup.sh" "$temp_file"; then
        echo "$SCRIPT_DIR/setup.sh" >> "$temp_file"
        updated=true
    fi

    if $updated; then
        mv "$temp_file" "$GO_FILE"
        echo "Go file has been updated."
    else
        rm "$temp_file"
        echo "No changes to the Go file necessary."
    fi
}

main() {
    echo "Initializing Oh My Zsh..."

    execute_script "slack_pkg_mgr.sh"
    execute_script "install.sh"
    execute_script "setup.sh"

    update_go_file

    echo "Oh My Zsh initialization completed."
}

main
