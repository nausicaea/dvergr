#!/usr/bin/env python3

import argparse
import hashlib
import http
import json
import os
import shutil
import stat
import sys
import tempfile
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable, Optional

MODRINTH_BASE_URL = "https://api.modrinth.com"
USER_AGENT = "nausicaea/minecraft/0.1.0 (developer@nausicaea.net)"


class NoCompatibleVersions(Exception):
    pass


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


def get_modrinth_request(url: str, modrinth_pat: str) -> Any:
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": modrinth_pat,
            "User-Agent": USER_AGENT,
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            if resp.status != http.HTTPStatus.OK:
                raise NotImplementedError()

            if not resp.headers["Content-Type"].startswith("application/json"):
                raise NotImplementedError()

            body = resp.read().decode("utf-8")

            return json.loads(body)
    except urllib.error.HTTPError:
        raise ValueError(f'Error requesting URL "{url}"')


def get_project_versions(
    project_id: str, modrinth_loader: str, minecraft_version: str, modrinth_pat: str
) -> Any:
    url = f"{MODRINTH_BASE_URL}/v2/project/{project_id}/version?loaders=%5B%22{modrinth_loader}%22%5D&game_versions=%5B%22{minecraft_version}%22%5D"
    try:
        return get_modrinth_request(url, modrinth_pat)
    except ValueError:
        raise ValueError(f'Error obtaining versions for the project "{project_id}"')


def get_version(
    project_id: str,
    version_id: str,
    modrinth_pat: str,
) -> Any:
    url = f"{MODRINTH_BASE_URL}/v2/project/{project_id}/version/{version_id}"
    try:
        return get_modrinth_request(url, modrinth_pat)
    except ValueError:
        raise ValueError(
            f'Error obtaining version "{version_id}" from project "{project_id}"'
        )


def get_primary_files(version: dict[str, Any]) -> Iterable[Any]:
    return filter(lambda f: f["primary"], version["files"])


def get_most_recent_version(versions: list[dict[str, Any]]) -> Any:
    return max(
        versions,
        key=lambda v: datetime.strptime(
            v["date_published"].split(".")[0], "%Y-%m-%dT%H:%M:%S"
        ),
    )


def get_required_dependencies(version: dict[str, Any]) -> Any:
    return filter(lambda f: f["dependency_type"] == "required", version["dependencies"])


def sha512(file: Path) -> str:
    return hashlib.sha512(file.open("rb").read()).hexdigest()


def download_files(files: Any, dest: Path) -> list[Path]:
    artifacts = list()
    for file in files:
        url = file["url"]
        checksum = file["hashes"]["sha512"]
        filename = file["filename"]
        file_dest = dest.joinpath(filename)
        artifacts.append(file_dest)
        (_, http_msg) = urllib.request.urlretrieve(url, file_dest)
        if http_msg.get("Content-Type") not in [
            "application/java-archive",
            "application/zip",
        ]:
            raise ValueError(
                "The artifact content type must be either a JAR archive or a ZIP file"
            )
        file_hash = sha512(file_dest)
        if file_hash != checksum:
            raise ValueError(
                f'Artifact hash mismatch: expected "{checksum}", got "{file_hash}"'
            )

    return artifacts


def process_version_by_id(
    project_id: str,
    version_id: str,
    dest: Path,
    modrinth_loader: str,
    minecraft_version: str,
    modrinth_pat: str,
) -> list[Path]:
    version = get_version(project_id, version_id, modrinth_pat)
    return process_version(
        version, dest, modrinth_loader, minecraft_version, modrinth_pat
    )


def process_dependencies(
    dependencies: Any,
    dest: Path,
    modrinth_loader: str,
    minecraft_version: str,
    modrinth_pat: str,
) -> list[Path]:
    artifacts = list()

    for dependency in dependencies:
        project_id = dependency["project_id"]
        version_id = dependency["version_id"]
        if project_id is not None:
            if version_id is not None:
                artifacts.extend(
                    process_version_by_id(
                        project_id,
                        version_id,
                        dest,
                        modrinth_loader,
                        minecraft_version,
                        modrinth_pat,
                    )
                )
            else:
                artifacts.extend(
                    process_project(
                        project_id,
                        dest,
                        modrinth_loader,
                        minecraft_version,
                        modrinth_pat,
                    )
                )

    return artifacts


def process_version(
    version: Any,
    dest: Path,
    modrinth_loader: str,
    minecraft_version: str,
    modrinth_pat: str,
) -> list[Path]:
    version_id = version["id"]
    version_name = version["name"]

    primary_files = get_primary_files(version)

    artifacts = download_files(primary_files, dest)

    dependencies = get_required_dependencies(version)

    try:
        artifacts.extend(
            process_dependencies(
                dependencies, dest, modrinth_loader, minecraft_version, modrinth_pat
            )
        )
    except NoCompatibleVersions:
        print(
            f'ignoring dependencies of version {version_id} (name: "{version_name}"): there are no versions compatible with Minecraft {minecraft_version} and the loader {modrinth_loader} (I cannot install dependencies from a different loader)',
            file=sys.stderr,
        )
    except:
        raise ValueError(
            f'error processing dependencies of the version {version_id} (name: "{version_name}")'
        )

    return artifacts


def process_project(
    project_id: str,
    dest: Path,
    modrinth_loader: str,
    minecraft_version: str,
    modrinth_pat: str,
) -> list[Path]:
    versions = get_project_versions(
        project_id, modrinth_loader, minecraft_version, modrinth_pat
    )
    loader_versions = list(filter(lambda v: modrinth_loader in v["loaders"], versions))
    if len(loader_versions) == 0:
        raise NoCompatibleVersions(
            f"there are no compatible versions of the project {project_id}"
        )
    most_recent_version = get_most_recent_version(loader_versions)
    return process_version(
        most_recent_version, dest, modrinth_loader, minecraft_version, modrinth_pat
    )


def download_project_artifacts(
    mc_version: str,
    loader: str,
    output: Path,
    projects: list[str],
    api_token: str,
    debug: bool = False,
):
    # Change to a temporary directory
    with tempfile.TemporaryDirectory() as temp:
        temp_dest = Path(temp)

        # Process all projects
        artifacts: list[Path] = list()
        for project in projects:
            artifacts.extend(
                process_project(project, temp_dest, loader, mc_version, api_token)
            )

        # Copy the artifacts into the destination directory
        for artifact in artifacts:
            if not output.is_dir():
                output.mkdir(parents=True)

            artifact_dest = output.joinpath(artifact.name)
            shutil.copyfile(artifact, artifact_dest)
            os.chmod(artifact_dest, stat.S_IRUSR | stat.S_IWUSR)


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
        "-i",
        "--input",
        type=Path,
        help="Specify a file with a list of newline-separated project IDs or slugs (short names)",
    )
    parser.add_argument(
        "projects", nargs="*", help="The ID or slug (short name) of a Modrinth project"
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

    input: Optional[Path] = matches.input
    if input is not None:
        with input.open("r") as i:
            projects: list[str] = [p.strip() for p in i]
    else:
        projects = matches.projects

    if len(projects) == 0:
        raise ValueError(
            "no projects specified: you must specify projects either from a file via -i/--input or via positional arguments"
        )

    download_project_artifacts(
        minecraft_version, loader, output, projects, api_token=api_token, debug=debug
    )


if __name__ == "__main__":
    main()
