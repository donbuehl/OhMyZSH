#!/bin/bash

DOWNLOAD_DIR="/boot/extra"
SLACKWARE_URL="https://slackware.uk/slackware/slackware64-current/slackware64/ap/"

version_gt() { 
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"
}

extract_version() {
    echo "$1" | grep -oP '\d+(\.\d+)+'
}

get_latest_version() {
    local package=$1
    local latest_version=$(curl -s $SLACKWARE_URL | grep -oP "${package}-[0-9.]+-(x86_64|noarch)-[0-9]+\.txz" | sort -V | tail -n1)
    if [ -z "$latest_version" ]; then
        echo "Error: No version of $package found"
        return 1
    fi
    echo "$latest_version"
}

check_package_exists() {
    local package=$1
    local existing_file=$(ls ${DOWNLOAD_DIR}/${package}-*.txz 2>/dev/null | head -n1)
    if [ -n "$existing_file" ] && [ -f "$existing_file" ]; then
        echo "$existing_file"
    else
        echo ""
    fi
}

install_package() {
    local package=$1
    local latest_version=$(get_latest_version $package)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to get latest version of $package"
        return 1
    fi
    echo "Installing $latest_version"
    wget -P "$DOWNLOAD_DIR" "${SLACKWARE_URL}${latest_version}"
    if [ $? -eq 0 ]; then
        installpkg "${DOWNLOAD_DIR}/${latest_version}"
    else
        echo "Error: Failed to download $latest_version"
        return 1
    fi
}

check_version() {
    local existing_file=$1
    local latest_version=$2
    local existing_version=$(extract_version "$(basename "$existing_file")")
    local new_version=$(extract_version "$latest_version")
    if version_gt "$new_version" "$existing_version"; then
        echo "newer"
    else
        echo "current"
    fi
}

delete_package() {
    local file=$1
    rm "$file"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: This script must be run as root"
        exit 1
    fi
}

main() {
    check_root

    local packages=("zsh" "tmux")
    for package in "${packages[@]}"; do
        echo "Processing $package..."
        local existing_file=$(check_package_exists "$package")
        
        if [ -z "$existing_file" ]; then
            install_package "$package"
        else
            local latest_version=$(get_latest_version $package)
            local version_status=$(check_version "$existing_file" "$latest_version")
            if [ "$version_status" = "newer" ]; then
                delete_package "$existing_file"
                install_package "$package"
            else
                echo "The existing version of $package is up to date. No action required."
            fi
        fi
        echo "------------------------"
    done
    
    echo "Process completed"
}

main