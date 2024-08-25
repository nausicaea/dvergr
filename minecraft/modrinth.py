#!/bin/python3

import argparse
import os
from pathlib import Path
from typing import Optional


class EnvDefault(argparse.Action):
    def __init__(self, envvar, required=True, default=None, **kwargs):
        if envvar is not None:
            if envvar in os.environ:
                default = os.environ[envvar]
        if required and default:
            required = False
        super(EnvDefault, self).__init__(default=default, required=required, **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, values)


def download_project_artifacts(
    mc_version: str,
    loader: str,
    output: Path,
    projects: list[str],
    api_token: Optional[str],
    debug: bool = False,
):
    raise NotImplementedError()


def main():
    parser = argparse.ArgumentParser(
        description="Provides read-only access to Minecraft mods, datapacks, and plugins via Modrinth"
    )
    parser.add_argument(
        "-d", "--debug", action="store_true", help="Enable debugging output"
    )
    parser.add_argument(
        "-l",
        "--loader",
        default="fabric",
        help="Specify the required loader (ex. fabric, datapack, etc.)",
    )
    parser.add_argument(
        "-t",
        "--api-token",
        action=EnvDefault,
        envvar="MODRINTH_PAT",
        help='Specify the Modrinth authentication token (default from environment variable "MODRINTH_PAT")',
    )
    parser.add_argument(
        "-V",
        "--minecraft-version",
        action=EnvDefault,
        envvar="MINECRAFT_VERSION",
        help='Specify the Minecraft version (default from environment variable "MINECRAFT_VERSION")',
    )
    parser.add_argument(
        "-O",
        "--output",
        type=Path,
        help="Specify the destination for downloaded artifacts (default is the current working directory)",
    )
    parser.add_argument(
        "projects", nargs="+", help="The ID or slug (short name) of a Modrinth project"
    )

    matches = parser.parse_args()
    debug: bool = matches.debug
    loader: str = matches.loader

    if matches.api_token is None or len(matches.api_token) == 0:
        raise ValueError(
            'missing Modrinth personal authentication token (variable "MODRINTH_PAT")'
        )
    api_token: str = matches.api_token

    if matches.minecraft_version is None or len(matches.minecraft_version) == 0:
        raise ValueError('missing Minecraft version (variable "MINECRAFT_VERSION")')
    minecraft_version: str = matches.minecraft_version

    if matches.output is not None:
        output: Path = matches.output.resolve(strict=True)
    else:
        output: Path = Path.cwd()

    projects: list[str] = matches.projects

    download_project_artifacts(
        minecraft_version, loader, output, projects, api_token=api_token, debug=debug
    )


if __name__ == "__main__":
    main()
