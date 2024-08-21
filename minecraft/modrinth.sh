#!/bin/ash

set -xe

download_datapack() {
    printf 'unimplemented\n'
    exit 1
}

download_mod() {
    true
}

main() {
    # Parse the subcommand
    case $1 in
        datapack) SUBCOMMAND="datapack"; break;;
        mod) SUBCOMMAND="mod"; break;;
        *) printf 'unimplemented\n'; exit 1;;
    esac

    # Ensure that the Modrinth API token is set
    if [ "x$MODRINTH_PAT" = "x" ]; then
        printf 'missing Modrinth personal authentication token (variable "MODRINTH_PAT")\n'
        exit 1
    fi

    case $SUBCOMMAND in
        datapack) download_datapack; break;;
        mod) download_mod; break;;
        *) exit 1;;
    esac
}

main "$1"
