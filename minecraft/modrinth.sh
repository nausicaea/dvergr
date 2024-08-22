#!/bin/sh

DEBUG=0
MODRINTH_BASE_URL=https://api.modrinth.com
MODRINTH_RATE_LIMIT=300  # per minute (see: https://docs.modrinth.com/#section/Ratelimits)
USER_AGENT="nausicaea/minecraft/0.1.0 (developer@nausicaea.net)"
ERROR_GENERAL=1
ERROR_HELP=3
ERROR_INTERNAL=4
ERROR_CURL=5
ERROR_JQ=6
ERROR_SH=7

println() {
    FORMAT="$1\n"
    shift
    printf "$FORMAT" "$@"
}

eprintln() {
    println "$@" >&2
}

debug() {
    if [ $DEBUG -ne 0 ]; then
        eprintln '[DEBUG] [%s] %s' "$1" "$2"
    fi
}

error() {
    eprintln '[ERROR] [%s] %s' "$1" "$2"
    return "$3"
}

# Copied urlencode_grouped_case shamelessly from https://unix.stackexchange.com/a/60698
urlencode() {
    string=$1; format=; set --
    while
        literal=${string%%[!-._~0-9A-Za-z]*}
        case "$literal" in
            ?*)
                format=$format%s
                set -- "$@" "$literal"
                string=${string#$literal};;
        esac
        case "$string" in
            "") false;;
        esac
    do
        tail=${string#?}
        head=${string%$tail}
        format=$format%%%02x
        set -- "$@" "'$head"
        string=$tail
    done
    printf "$format\\n" "$@"
}

show_help_and_exit() {
    eprintln '\n\
Usage:  modrinth [OPTIONS] COMMAND [ID_OR_SLUG ...]\n\
\n\
Provides read-only access to Minecraft mods, datapacks, and plugins via Modrinth\n\
\n\
Commands:\n\
  help          Print this message and exit\n\
  download      Download project artifacts and dependencies\n\
\n\
Arguments:\n\
  ID_OR_SLUG    The ID or slug (short name) of a Modrinth project
Global Options:\n\
  -h            Print this message and exit\n\
  -t            Specify the Modrinth authentication token (default from environment variable "MODRINTH_PAT")\n\
  -V            Specify the Minecraft version (default from environment variable "MINECRAFT_VERSION")\n\
  -D            Specify the destination for downloaded artifacts (default is the current working directory)\n\
\n\
'
    return $ERROR_HELP
}

get_project_versions() {
    debug "$FUNCNAME" "(project_id: $1)"
    project=$(urlencode "$1") || return $(error "$FUNCNAME" 'urlencode' "$?")
    curl \
        --silent \
        --header "Authorization: $MODRINTH_PAT" \
        --header "User-Agent: $USER_AGENT" \
        "$MODRINTH_BASE_URL/v2/project/$project/version?loaders=%5B%22fabric%22%5D&game_versions=%5B%22$MINECRAFT_VERSION%22%5D"
}

get_version() {
    debug "$FUNCNAME" "(project_id: $1, version_id: $2)"
    curl \
        --silent \
        --header "Authorization: $MODRINTH_PAT" \
        --header "User-Agent: $USER_AGENT" \
        "$MODRINTH_BASE_URL/v2/project/$1/version/$2"
}

get_most_recent_version() {
    debug "$FUNCNAME" '(...)'
    echo "$1" | 
        jq -c 'map(select(.loaders[] == "fabric")) | max_by(.date_published | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | mktime)'
}

get_primary_files() {
    debug "$FUNCNAME" '(...)'
    echo "$1" | 
        jq -c '.files | map(select(.primary))'
}

get_required_dependencies() {
    debug "$FUNCNAME" '(...)'
    echo "$1" | 
        jq -r '.dependencies | map(select(.dependency_type == "required") | "\(.project_id),\(.version_id)") | .[]'
}

download_files() {
    debug "$FUNCNAME" '(...)'
    COMMAND_LINES=$(
        echo "$1" | 
            jq -r '.[] | "echo \(.hashes.sha512 | @sh ) \(.filename | @sh) > \(.filename | @sh).sha512; curl --silent -o \(.filename | @sh) \(.url | @sh); sha512sum -s -c \(.filename | @sh).sha512; echo $(realpath ./\(.filename | @sh))"'
    ) || return $(error "$FUNCNAME" 'jq' "$?")

    sh -c "$COMMAND_LINES"
}

download_version() {
    VERSION_NAME="$(echo "$1" | jq -r '.name')"
    debug "$FUNCNAME" "downloading artefacts for '$VERSION_NAME'"
    PRIMARY_FILES=$(get_primary_files "$1") || return $(error "$FUNCNAME" 'get_primary_files' "$?")
    download_files "$PRIMARY_FILES" || return $(error "$FUNCNAME" 'download_files' "$?")
    DEPENDENCIES=$(get_required_dependencies "$1") || return $(error "$FUNCNAME" 'get_required_dependencies' "$?")
    if [ "x$DEPENDENCIES" != "x" ]; then
        debug "$FUNCNAME" "processing dependencies for '$VERSION_NAME'"
        process_dependencies "$DEPENDENCIES" || return $(error "$FUNCNAME" 'process_dependencies' "$?")
    fi
}

process_version() {
    debug "$FUNCNAME" "processing project ID '$1' and version ID '$2'"

    VERSION=$(get_version "$1" "$2") || return $(error "$FUNCNAME" 'project_id cut' "$?")
    download_version "$VERSION" || return $(error "$FUNCNAME" 'download_version' "$?")
}

process_dependencies() {
    for dependency in "$1"; do
        project_id=$(echo $dependency | cut -f1 -d',') || return $(error "$FUNCNAME" 'project_id cut' "$?")
        version_id=$(echo $dependency | cut -f2 -d',') || return $(error "$FUNCNAME" 'version_id cut' "$?")
        if [ "x$project_id" != "x" ] && [ $project_id != "null" ]; then
            if [ "x$version_id" != "x" ] && [ $version_id != "null" ]; then
                process_version "$project_id" "$version_id" || return $(error "$FUNCNAME" 'process_version' "$?")
            else
                process_project "$project_id" || return $(error "$FUNCNAME" 'process_project' "$?")
            fi
        fi
    done
}

process_project() {
    debug "$FUNCNAME" "processing project ID '$1'"

    VERSIONS=$(get_project_versions "$1") || return $(error "$FUNCNAME" 'get_project_versions'"$?")
    MOST_RECENT_VERSION=$(get_most_recent_version "$VERSIONS") || return $(error "$FUNCNAME" 'get_most_recent_version' "$?")
    if [ "x$MOST_RECENT_VERSION" = "x" ] || [ "$MOST_RECENT_VERSION" = "null" ]; then
        return $(error "$FUNCNAME" "no matching versions for project ID '$1'" "$ERROR_GENERAL")
    fi

    download_version "$MOST_RECENT_VERSION" || return $(error "$FUNCNAME" 'download_version' "$?")
}

subcommand_download() {
    CWD=$(pwd) || return $(error "$FUNCNAME" 'pwd' "$?")
    cd $(mktemp -d) || return $(error "$FUNCNAME" 'mktemp' "$?")

    for project in "$@"; do
        # Download all files related to the project and the specified minecraft version
        ARTEFACTS=$(process_project "$project") || return $(error "$FUNCNAME" 'process_project' "$?")

        # Copy the resultant files to the destination directory
        if [ "x$DESTINATION" != "x" ]; then
            for artefact in $ARTEFACTS; do
                install -v -m 0600 -D -t "$DESTINATION" "$artefact" || return $(error "$FUNCNAME" 'install' "$?")
            done
        else
            for artefact in $ARTEFACTS; do
                install -v -m 0600 -D -t "$CWD" "$artefact" || return $(error "$FUNCNAME" 'install' "$?")
            done
        fi
    done

    cd $CWD
}

main() {
    if [ $# -eq 0 ]; then
        show_help_and_exit || return
    fi

    ARGS=$(getopt 'vht:V:D:' $*) || show_help_and_exit || return

    set -- $ARGS

    while :; do
        case "$1" in
            -v)
                DEBUG=1
                shift
                ;;
            -h) 
                show_help_and_exit || return
                ;;
            -V)
                MINECRAFT_VERSION="$2"
                shift
                shift
                ;;
            -D)
                RAW_DESTINATION="$2"
                shift
                shift
                ;;
            -t)
                MODRINTH_PAT="$2"
                shift
                shift
                ;;
            --)
                shift
                break
                ;;
        esac
    done

    # Parse the subcommand
    case "$1" in
        help)
            show_help_and_exit || return
            ;;
        download)
            SUBCOMMAND="download"
            ;;
        *) 
            eprintln 'invalid subcommand "%s"' "$1"
            show_help_and_exit || return
            ;;
    esac

    shift

    # Ensure that the Modrinth API token is set
    if [ "x$MODRINTH_PAT" = "x" ]; then
        eprintln 'missing Modrinth personal authentication token (variable "MODRINTH_PAT")'
        show_help_and_exit || return
    fi

    # Ensure that the Minecraft version is set
    if [ "x$MINECRAFT_VERSION" = "x" ]; then
        eprintln 'missing Minecraft version (variable "MINECRAFT_VERSION")'
        show_help_and_exit || return
    fi

    # Ensure that the destination is real path
    if [ "x$RAW_DESTINATION" != "x" ]; then
        DESTINATION=$(realpath "$RAW_DESTINATION")
        if [ $? -ne 0 ]; then
            eprintln 'no such file or directory "%s"' "$RAW_DESTINATION"
            show_help_and_exit || return
        fi
    fi

    case $SUBCOMMAND in
        download)
            subcommand_download "$@" || return $(error "$FUNCNAME" 'subcommand_download' "$?")
            ;;
        *)
            eprintln 'internal error: unknown subcommand "%s"' "$SUBCOMMAND"
            return $ERROR_INTERNAL
            ;;
    esac
}

main "$@"
