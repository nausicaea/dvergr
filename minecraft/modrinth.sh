#!/bin/sh

set -ex

MODRINTH_BASE_URL=https://staging-api.modrinth.com
MODRINTH_RATE_LIMIT=300  # per minute (see: https://docs.modrinth.com/#section/Ratelimits)
USER_AGENT="nausicaea/minecraft/0.1.0 (developer@nausicaea.net)"

eprintln() {
    FORMAT="$1\n"
    shift
    printf "$FORMAT" "$@" >&2
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

show_help() {
    eprintln 'todo'
    exit 0
}

download_datapack() {
    eprintln 'todo'
    exit 1
}

get_project_versions() {
    curl \
        --silent \
        --header "Authorization: $MODRINTH_PAT" \
        --header "User-Agent: $USER_AGENT" \
        "$MODRINTH_BASE_URL/v2/project/$1/version?loaders=%5B%22fabric%22%5D&game_versions=%5B%22$MINECRAFT_VERSION%22%5D"
}

get_version() {
    curl \
        --silent \
        --header "Authorization: $MODRINTH_PAT" \
        --header "User-Agent: $USER_AGENT" \
        "$MODRINTH_BASE_URL/v2/version/$1"
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

download_files() {
    sh <(
        echo "$1" | 
            jq -r '.[] | "echo \(.hashes.sha512 | @sh ) \(.filename | @sh) > \(.filename | @sh).sha512; curl --silent -o \(.filename | @sh) \(.url | @sh); sha512sum --status --strict -c \(.filename | @sh).sha512; echo $(pwd)/\(.filename | @sh)"'
    )
}

download_version() {
    PRIMARY_FILES=$(get_primary_files "$1")
    download_files "$PRIMARY_FILES"
    download_required_dependencies "$1"
}

download_mod_project() {
    VERSIONS=$(get_project_versions "$1")
    MOST_RECENT_VERSION=$(get_most_recent_version "$VERSIONS")
    if [ "x$MOST_RECENT_VERSION" = "x" ] || [ "$MOST_RECENT_VERSION" = "null" ]; then
        eprintln 'project %s has no matching versions' "$1"
        exit 1;
    fi
    download_version "$MOST_RECENT_VERSION"
}

# Dependency example
# {"game_versions":["1.21"],"loaders":["fabric"],"id":"qAKuAKD7","project_id":"HXF82T3G","author_id":"oB0UcvPI","featured":false,"name":"21.0.0.18 for Fabric 1.21","version_number":"21.0.0.18","changelog":"```\nAdd Missing translation and update (french) (#2258)\n","changelog_url":null,"date_published":"2024-08-19T22:38:23.294690Z","downloads":1052,"version_type":"beta","status":"listed","requested_status":null,"files":[{"hashes":{"sha1":"e9e7d6643f313e7a5919c8070d708b5bcc03fa61","sha512":"d4f4139ff3daab8409478db9145cf8861f36e70f17f00a85219e7bb1512c7c804d73658477cb3d17e598de2dde52012ece0a648dcad0a3035ce667ea4a4fb0ef"},"url":"https://cdn.modrinth.com/data/HXF82T3G/versions/qAKuAKD7/BiomesOPlenty-fabric-1.21-21.0.0.18.jar","filename":"BiomesOPlenty-fabric-1.21-21.0.0.18.jar","primary":true,"size":22335894,"file_type":null}],"dependencies":[{"version_id":null,"project_id":"P7dR8mSH","file_name":null,"dependency_type":"required"},{"version_id":null,"project_id":"kkmrDlKT","file_name":null,"dependency_type":"required"},{"version_id":null,"project_id":"s3dmwKy5","file_name":null,"dependency_type":"required"}]}
download_required_dependencies() {
    echo "$1" | 
        jq -r '.dependencies[] | select(.dependency_type == "required") | [.project_id, .version_id] | @csv' | 
        while IFS=',' read -r -d, project_id version_id; do 
            eprintf 'processing dependency project:%s version:%s\n' $project_id - $version_id
            if [ "x$project_id" != "x" ]; then
                download_mod_project "$project_id"
            elif [ "x$version_id" != "x" ]; then
                download_version "$version_id"
            fi
        done
}

subcommand_datapack() {
    download_datapack
}

subcommand_mod() {
    download_mod_project "$1"
}

main() {
    if [ "x$1" = "x" ]; then
        show_help
    fi

    # Parse the subcommand
    case $1 in
        help) show_help; break;;
        datapack) SUBCOMMAND="datapack"; break;;
        mod) SUBCOMMAND="mod"; break;;
        *) printf 'unimplemented\n'; exit 1;;
    esac

    # Ensure that the Modrinth API token is set
    if [ "x$MODRINTH_PAT" = "x" ]; then
        printf 'missing Modrinth personal authentication token (variable "MODRINTH_PAT")\n'
        exit 1
    fi

    # Ensure that the Minecraft version is set
    if [ "x$MINECRAFT_VERSION" = "x" ]; then
        printf 'missing Minecraft version (variable "MINECRAFT_VERSION")\n'
        exit 1
    fi

    # Url-encode the search string
    SEARCH_STRING=$(urlencode "$2")

    case $SUBCOMMAND in
        datapack) subcommand_datapack; break;;
        mod) subcommand_mod "$SEARCH_STRING"; break;;
        *) exit 1;;
    esac
}

main "$1" "$2"
