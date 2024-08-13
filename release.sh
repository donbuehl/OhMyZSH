#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

clean_old_archives() {
    rm -f archive/*.txz
}

main() {
    clean_old_archives
    bash package.sh;
    echo "Attempting to run package.sh"
    if ! bash package.sh; then
        echo "Error: Failed to run package.sh. Please check the script for errors."
        exit 1
    fi

    git add .version OhMyZSH.plg archive/*.txz
    VERSION=$(cat .version)
    git commit -m "Release version $VERSION"
    git tag -a "v$VERSION" -m "Version $VERSION"
    
    if [ -z "$SSH_AUTH_SOCK" ]; then
        echo "SSH-Agent is not running. You may need to enter your passphrase."
    fi

    if ! git push origin main --tags; then
        echo "Error: Failed to push to remote. Please check your SSH setup and permissions."
        exit 1
    fi

    echo "Release $VERSION successfully created and pushed."
}

main