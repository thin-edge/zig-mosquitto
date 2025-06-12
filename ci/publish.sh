#!/bin/bash
set -e
# -----------------------------------------------
# Publish package to Cloudsmith.io
# -----------------------------------------------
help() {
  cat <<EOF
Publish linux and tarball packages from a path to a package repository

All the necessary dependencies will be downloaded automatically if they are not already present

Usage:
    $0

Flags:
    --token <string>            Debian access token used to authenticate the commands
    --owner <string>            Debian repository owner
    --repo <string>             Name of the debian repository to publish to
    --path <source_path>        Directory containing the files to publish
    --help|-h                   Show this help

Optional Environment variables (instead of flags)

PUBLISH_TOKEN            Equivalent to --token flag
PUBLISH_OWNER            Equivalent to --owner flag
PUBLISH_REPO             Equivalent to --repo flag

Examples:
    $0 \\
        --token "mywonderfultoken" \\
        --repo "community" \\
        --path ./dist

    \$ Publish all debian/alpine/rpm/tar.gz packages found under ./dist
EOF
}

PUBLISH_TOKEN="${PUBLISH_TOKEN:-}"
PUBLISH_OWNER="${PUBLISH_OWNER:-thinedge}"
PUBLISH_REPO="${PUBLISH_REPO:-community}"
SOURCE_PATH="./"


#
# Argument parsing
#
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    case "$1" in
        # Repository owner
        --owner)
            PUBLISH_OWNER="$2"
            shift
            ;;

        # Token used to authenticate publishing commands
        --token)
            PUBLISH_TOKEN="$2"
            shift
            ;;

        # Where to look for the debian files to publish
        --path)
            SOURCE_PATH="$2"
            shift
            ;;

        # Which debian repo to publish to (under the given host url)
        --repo)
            PUBLISH_REPO="$2"
            shift
            ;;

        --help|-h)
            help
            exit 0
            ;;
        
        -*)
            echo "Unrecognized flag" >&2
            help
            exit 1
            ;;

        *)
            POSITIONAL+=("$1")
            ;;
    esac
    shift
done
set -- "${POSITIONAL[@]}"

# Add local tools path
LOCAL_TOOLS_PATH="$HOME/.local/bin"
export PATH="$LOCAL_TOOLS_PATH:$PATH"

# Install tooling if missing
if ! [ -x "$(command -v cloudsmith)" ]; then
    echo 'Install cloudsmith cli' >&2
    if command -v pip3 &>/dev/null; then
        pip3 install --upgrade cloudsmith-cli
    elif command -v pip &>/dev/null; then
        pip install --upgrade cloudsmith-cli
    else
        echo "Could not install cloudsmith cli. Reason: pip3/pip is not installed"
        exit 2
    fi
fi

read_name_from_file() {
    #
    # Detect the package name from a file
    # e.g. output/tedge-openrc_0.0.0~rc0.tar.gz => tedge-openrc
    #
    name="$(basename "$1")"
    echo "Reading name from file: $name" >&2
    case "$name" in
        *.tar.gz)
            echo "${name%.tar.gz}" | cut -d'_' -f1
            ;;
        *)
            echo "${name%.*}" | cut -d'_' -f1
            ;;
    esac
}

read_version_from_file() {
    #
    # Detect the package version from a file
    # e.g. output/tedge-openrc_0.0.0~rc0.tar.gz => 0.0.0~rc0
    #
    name="$(basename "$1")"
    echo "Reading version from file: $name" >&2
    case "$name" in
        *_*)
            echo "${name%.*}" | sed 's/.tar$//g' | cut -d'_' -f2
            ;;
    esac
}


publish_linux() {
    local sourcedir="$1"
    local pattern="$2"
    local package_type="$3"
    local sub_path="$4"

    local upload_path="${PUBLISH_OWNER}/${PUBLISH_REPO}"
    if [ -n "$sub_path" ]; then
        upload_path="$upload_path/$sub_path"
    fi

    # Notes: Currently Cloudsmith does not support the following (this might change in the future)
    #  * distribution and distribution_version must be selected from values in the list. use `cloudsmith list distros` to get the list
    #  * The component can not be set and is currently fixed to 'main'
    find "$sourcedir" -name "$pattern" -print0 | while read -r -d $'\0' file
    do
        cloudsmith upload "$package_type" "$upload_path" "$file" \
            --no-wait-for-sync \
            --api-key "${PUBLISH_TOKEN}"
    done
}

publish_raw() {
    local sourcedir="$1"
    local pattern="$2"
    local version="$3"

    # Notes: Currently Cloudsmith does not support the following (this might change in the future)
    #  * distribution and distribution_version must be selected from values in the list. use `cloudsmith list distros` to get the list
    #  * The component can not be set and is currently fixed to 'main'
    find "$sourcedir" -name "$pattern" -print0 | while read -r -d $'\0' file
    do
        # parse package info from filename
        pkg_name=$(read_name_from_file "$file")
        pkg_version="${version:-}"
        if [ -z "$pkg_version" ]; then
            pkg_version=$(read_version_from_file "$file")
        fi

        if [ -z "$pkg_name" ]; then
            echo "Could not detect package name from file. file=$file" >&2
            exit 1
        fi

        if [ -z "$pkg_version" ]; then
            echo "Could not detect package version from file. file=$file" >&2
            exit 1
        fi

        # Create tmp package without the version information
        # so that the latest url is static
        mkdir -p tmp
        tmp_file="tmp/${pkg_name}.tar.gz"
        cp "$file" "$tmp_file"

        echo "Uploading file: $file (name=$pkg_name, version=$pkg_version, file=$tmp_file)"
        cloudsmith upload raw "${PUBLISH_OWNER}/${PUBLISH_REPO}" "$tmp_file" \
            --name "$pkg_name" \
            --version "$pkg_version" \
            --no-wait-for-sync \
            --api-key "${PUBLISH_TOKEN}"

        rm -rf tmp
    done
}

publish_raw "$SOURCE_PATH" "*.tar.gz"

publish_linux "$SOURCE_PATH" "*.deb" deb "any-distro/any-version"
publish_linux "$SOURCE_PATH" "*.rpm" rpm "any-distro/any-version"
publish_linux "$SOURCE_PATH" "*.apk" alpine "alpine/any-version"
