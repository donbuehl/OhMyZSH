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
    echo "Checking for the latest version of $package..."
    local latest_version=$(curl -s $SLACKWARE_URL | grep -oP "${package}-[0-9.]+-(x86_64|noarch)-[0-9]+\.txz" | sort -V | tail -n1)
    if [ -z "$latest_version" ]; then
        echo "Error: No version of $package found"
        return 1
    fi
    echo "Latest version of $package: $latest_version"
    echo "$latest_version"
}

check_existing_version() {
    local package=$1
    local existing_file=$(ls ${DOWNLOAD_DIR}/${package}-*.txz 2>/dev/null | head -n1)
    if [ -n "$existing_file" ]; then
        local existing_version=$(extract_version "$(basename "$existing_file")")
        echo "Checking if $package: $(basename "$existing_file") is already installed"
        echo "$existing_file"
    else
        echo "No existing version of $package found"
        echo ""
    fi
}

download_package() {
    local package=$1
    echo "Installing $package"
    wget -P "$DOWNLOAD_DIR" "${SLACKWARE_URL}${package}"
    echo "$package has been successfully downloaded."
}

update_package() {
    local package=$1
    
    local latest_version=$(get_latest_version $package)
    [ $? -ne 0 ] && return 1
    
    local existing_file=$(check_existing_version $package)
    
    if [ -n "$existing_file" ]; then
        local existing_version=$(extract_version "$(basename "$existing_file")")
        local new_version=$(extract_version "$latest_version")
        
        if version_gt "$new_version" "$existing_version"; then
            echo "Replacing $existing_version of $package with $latest_version"
            rm "$existing_file"
            download_package $latest_version
        else
            echo "The existing version $existing_version of $package is already up to date. No download required."
        fi
    else
        download_package $latest_version
    fi
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: This script must be run as root"
        exit 1
    fi
}

main() {
    check_root
    update_package "zsh"
    echo "------------------------"
    update_package "tmux"
    echo "Process completed"
}

main
