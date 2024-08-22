#!/bin/sh

set -ex

MODRINTH_BASE_URL=https://api.modrinth.com
MODRINTH_RATE_LIMIT=300  # per minute (see: https://docs.modrinth.com/#section/Ratelimits)
USER_AGENT="nausicaea/minecraft/0.1.0 (developer@nausicaea.net)"
ERROR_GENERAL=1
ERROR_HELP=3
ERROR_INTERNAL=4
ERROR_CURL=5

println() {
    FORMAT="$1\n"
    shift
    printf "$FORMAT" "$@"
}

eprintln() {
    println "$@" >&2
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
    eprintln 'show_help_and_exit: todo'
    exit $ERROR_HELP
}

download_datapack() {
    eprintln 'download_datapack: todo'
    exit $ERROR_GENERAL
}

get_project_versions() {
    curl \
        --silent \
        --header "Authorization: $MODRINTH_PAT" \
        --header "User-Agent: $USER_AGENT" \
        "$MODRINTH_BASE_URL/v2/project/$1/version?loaders=%5B%22fabric%22%5D&game_versions=%5B%22$MINECRAFT_VERSION%22%5D"

    if [ $? -ne 0 ]; then
        eprintln 'get_project_versions: curl error: %s' "$?"
        exit ERROR_CURL
    fi
}

get_version() {
    curl \
        --silent \
        --header "Authorization: $MODRINTH_PAT" \
        --header "User-Agent: $USER_AGENT" \
        "$MODRINTH_BASE_URL/v2/version/$1"

    if [ $? -ne 0 ]; then
        eprintln 'get_version: curl error: %s' "$?"
        exit ERROR_CURL
    fi
}

get_most_recent_version() {
    jq_semver_cmp='def opt(f): . as $in | try f catch $in; def semver_cmp: sub("\\+.*$"; "") | capture("^(?<v>[^-]+)(?:-(?<p>.*))?$") | [.v, .p // empty] | map(split(".") | map(opt(tonumber))) | .[1] |= (. // {});'
    echo "$1" | 
        jq -c "$jq_semver_cmp"'map(select(.loaders[] == "fabric")) | max_by(.version_number | semver_cmp)'
}

get_primary_files() {
    echo "$1" | 
        jq -c '.files | map(select(.primary))'
}

get_required_dependencies() {
    eprintln 'FIXME: Something is wrong here'
    echo "$1" | jq -r '.dependencies[] | select(.dependency_type == "required") | [.project_id, .version_id] | @csv'
}

download_files() {
    COMMAND_LINES=$(echo "$1" | jq -r '.[] | "echo \(.hashes.sha512 | @sh ) \(.filename | @sh) > \(.filename | @sh).sha512; curl --silent -o \(.filename | @sh) \(.url | @sh); sha512sum -s -c \(.filename | @sh).sha512; echo $(realpath ./\(.filename | @sh))"')
    sh -c "$COMMAND_LINES"
}

download_version() {
    PRIMARY_FILES=$(get_primary_files "$1")
    download_files "$PRIMARY_FILES"
    DEPENDENCIES=$(get_required_dependencies "$1")
    download_required_dependencies "$DEPENDENCIES"
}

download_project() {
    VERSIONS=$(get_project_versions "$1")
    MOST_RECENT_VERSION=$(get_most_recent_version "$VERSIONS")
    if [ "x$MOST_RECENT_VERSION" = "x" ] || [ "$MOST_RECENT_VERSION" = "null" ]; then
        eprintln 'project %s has no matching versions' "$1"
        exit $ERROR_GENERAL;
    fi
    download_version "$MOST_RECENT_VERSION"
}

# Dependency example
# {"game_versions":["1.21"],"loaders":["fabric"],"id":"qAKuAKD7","project_id":"HXF82T3G","author_id":"oB0UcvPI","featured":false,"name":"21.0.0.18 for Fabric 1.21","version_number":"21.0.0.18","changelog":"```\nAdd Missing translation and update (french) (#2258)\n","changelog_url":null,"date_published":"2024-08-19T22:38:23.294690Z","downloads":1052,"version_type":"beta","status":"listed","requested_status":null,"files":[{"hashes":{"sha1":"e9e7d6643f313e7a5919c8070d708b5bcc03fa61","sha512":"d4f4139ff3daab8409478db9145cf8861f36e70f17f00a85219e7bb1512c7c804d73658477cb3d17e598de2dde52012ece0a648dcad0a3035ce667ea4a4fb0ef"},"url":"https://cdn.modrinth.com/data/HXF82T3G/versions/qAKuAKD7/BiomesOPlenty-fabric-1.21-21.0.0.18.jar","filename":"BiomesOPlenty-fabric-1.21-21.0.0.18.jar","primary":true,"size":22335894,"file_type":null}],"dependencies":[{"version_id":null,"project_id":"P7dR8mSH","file_name":null,"dependency_type":"required"},{"version_id":null,"project_id":"kkmrDlKT","file_name":null,"dependency_type":"required"},{"version_id":null,"project_id":"s3dmwKy5","file_name":null,"dependency_type":"required"}]}
download_required_dependencies() {
    echo "$1" | 
        while IFS=',' read -r -d, project_id version_id; do 
            eprintln 'processing dependency project:%s version:%s' $project_id $version_id
            if [ "x$project_id" != "x" ]; then
                download_project "$project_id"
            elif [ "x$version_id" != "x" ]; then
                download_version "$version_id"
            fi
        done
}

subcommand_datapack() {
    download_datapack
}

subcommand_mod() {
    cd $(mktemp -d)

    for raw_query in "$@"; do
        eprintln 'processing mod "%s"' "$raw_query"

        # Url-encode the search string
        PROJECT_SLUG_OR_ID=$(urlencode "$raw_query")

        # Download all files related to the project and the specified minecraft version
        FILES=$(download_project "$PROJECT_SLUG_OR_ID")

        # Copy the resultant files to the destination directory
        if [ "x$DESTINATION" != "x" ]; then
            install -m 0644 -D -t "$DESTINATION" "$FILES"
        fi
    done

    cd -
}

main() {
    if [ $# -eq 0 ]; then
        show_help_and_exit
    fi

    ARGS=$(getopt 'ht:V:D:' $*)

    if [ $? -ne 0 ]; then
        show_help_and_exit
    fi

    set -- $ARGS

    while :; do
        case "$1" in
            -h) 
                show_help_and_exit
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
            show_help_and_exit
            ;;
        datapack)
            SUBCOMMAND="datapack"
            ;;
        mod)
            SUBCOMMAND="mod"
            ;;
        *) 
            eprintln 'invalid subcommand "%s"' "$1"
            show_help_and_exit
            ;;
    esac

    shift

    # Ensure that the Modrinth API token is set
    if [ "x$MODRINTH_PAT" = "x" ]; then
        eprintln 'missing Modrinth personal authentication token (variable "MODRINTH_PAT")'
        exit $ERROR_GENERAL
    fi

    # Ensure that the Minecraft version is set
    if [ "x$MINECRAFT_VERSION" = "x" ]; then
        eprintln 'missing Minecraft version (variable "MINECRAFT_VERSION")'
        exit $ERROR_GENERAL
    fi

    # Ensure that the destination is real path
    if [ "x$RAW_DESTINATION" != "x" ]; then
        DESTINATION=$(realpath "$RAW_DESTINATION")
        if [ $? -ne 0 ]; then
            eprintln 'no such file or directory "%s"' "$RAW_DESTINATION"
            show_help_and_exit
        fi
    fi

    case $SUBCOMMAND in
        datapack) 
            subcommand_datapack
            ;;
        mod)
            subcommand_mod "$@"
            ;;
        *)
            eprintln 'internal error: unknown subcommand "%s"' "$SUBCOMMAND"
            exit $ERROR_INTERNAL
            ;;
    esac
}

main "$@"
