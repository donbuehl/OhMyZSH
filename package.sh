#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

clean_old_archives() {
    rm -f archive/*.txz
}

PLUGIN_NAME="OhMyZSH"
PLG_FILE="$(pwd)/${PLUGIN_NAME}.plg"
CURRENT_DATE=$(date +"%y.%m.%d")
VERSION_FILE=".version"
SRC_DIR="src"
TMP_DIR="/tmp/${PLUGIN_NAME}_build"
ARCHIVE_DIR="$(pwd)/archive"

delete_old_version_files() {
    find . -name ".version_*" -type f | while read file; do
        file_date=$(echo $file | sed 's/.*version_//')
        if [[ "$file_date" < "$CURRENT_DATE" ]]; then
            rm "$file"
            echo "Deleted old version file: $file"
        fi
    done
}

handle_version_increment() {
    local version_file=".version_${CURRENT_DATE}"
    local daily_version

    if [ -f "$version_file" ]; then
        daily_version=$(($(cat "$version_file") + 1))
    else
        daily_version=1
        delete_old_version_files
    fi
    echo $daily_version > "$version_file"
    echo $daily_version
}

get_version() {
    if [ -f "$VERSION_FILE" ]; then
        local last_version=$(cat "$VERSION_FILE")
        local last_date=$(echo $last_version | cut -d'-' -f1)
        local last_build=$(echo $last_version | cut -d'-' -f2)
        
        local current_date=$(date +"%y.%m.%d")
        
        if [ "$current_date" = "$last_date" ]; then
            build=$((last_build + 1))
        else
            build=1
        fi
        
        VERSION="${current_date}-${build}"
    else
        VERSION="$(date +"%y.%m.%d")-1"
    fi
    
    echo $VERSION > "$VERSION_FILE"
    echo "Creating version: $VERSION"
}

prepare_archive() {
    rm -rf "${TMP_DIR}"
    mkdir -p "${TMP_DIR}/usr/local/emhttp/plugins/${PLUGIN_NAME}"
    if [ -d "$SRC_DIR" ]; then
        cp -R "$SRC_DIR"/* "${TMP_DIR}/usr/local/emhttp/plugins/${PLUGIN_NAME}/"
        echo "Archive contents prepared"
    else
        echo "Error: Source directory '$SRC_DIR' not found"
        exit 1
    fi
}

create_archive() {
    local archive_name="${PLUGIN_NAME}-${VERSION}.txz"
    
    mkdir -p "$ARCHIVE_DIR"
    tar -cJf "${ARCHIVE_DIR}/${archive_name}" -C "${TMP_DIR}" .
    rm -rf "${TMP_DIR}"
    echo "Archive ${archive_name} has been created"
}

update_plg_file() {
    local archive_name="${PLUGIN_NAME}-${VERSION}.txz"
    
    if [ ! -f "$PLG_FILE" ]; then
        echo "Error: .plg file not found: $PLG_FILE"
        exit 1
    fi

    sed -i "s|<!ENTITY version  .*>|<!ENTITY version   \"${VERSION}\">|" "$PLG_FILE"
    sed -i "s|<!ENTITY plgNAME  .*>|<!ENTITY plgNAME   \"${PLUGIN_NAME}-${VERSION}\">|" "$PLG_FILE"
    sed -i "s|<FILE Name=\".*${PLUGIN_NAME}-.*\.txz\">|<FILE Name=\"&plgCONF;/${archive_name}\">|" "$PLG_FILE"
    sed -i "s|<URL>.*${PLUGIN_NAME}-.*\.txz</URL>|<URL>&pkgURL;/${archive_name}</URL>|" "$PLG_FILE"
    
    # Update the CHANGES section
    sed -i "/^<CHANGES>/,/<\/CHANGES>/c\<CHANGES>\n### ${VERSION}\n- Update to version ${VERSION}\n<\/CHANGES>" "$PLG_FILE"
    
    echo ".plg file updated with version ${VERSION}"
}

main() {
    clean_old_archives
    get_version
    prepare_archive
    create_archive
    update_plg_file
    echo "Archive creation and .plg update completed successfully"
}

main
