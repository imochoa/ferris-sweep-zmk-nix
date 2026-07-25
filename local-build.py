#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "pyyaml>=6.0",
#     "sh>=2.0",
# ]
# ///

"""
Local ZMK firmware build script using Docker/Podman.
This script reads build.yaml and builds all configurations.
"""

# NO UV IN DEVCONTAINER
# REWRITE TO GENERATE SHELL COMMANDS INSTEAD OF USING UV


import os
from pathlib import Path
import yaml

import sh
from sh import just

from enum import StrEnum, auto


class YML(StrEnum):
    include = auto()
    board = auto()
    shield = auto()
    snippet = auto()
    cmake_args = "cmake-args"
    artifact_name = "artifact-name"


def main() -> None:
    # Configuration (matching GitHub workflow defaults)
    matrix_path = Path("build.yaml")
    # config_path = os.getenv("CONFIG_PATH", "config")
    # fallback_binary = os.getenv("FALLBACK_BINARY", "bin")
    # archive_name = os.getenv("ARCHIVE_NAME", "firmware")

    print(f"Fetching build matrix from {matrix_path}")
    with open(matrix_path) as f:
        build_matrix = yaml.safe_load(f)

    # board+shield are used to merge everything else!
    b_includes = build_matrix[YML.include]
    boardshield_map = {
        (m[YML.board], m[YML.shield]): {
            YML.board: m[YML.board],
            YML.shield: m[YML.shield],
            YML.snippet: [],
            YML.cmake_args: [],
            YML.artifact_name: [],
        }
        for m in b_includes
    }

    # collect
    for m in b_includes:
        obj = boardshield_map[(m[YML.board], m[YML.shield])]
        for k in (YML.snippet, YML.cmake_args, YML.artifact_name):
            str_value = m.get(k, "").strip()
            list_value = [] if not str_value else [str_value]
            obj[k].extend(list_value)

    # merge
    builds = []
    for obj in boardshield_map.values():
        # TODO: the ordering can be used to overwrite defaults...
        obj[YML.snippet] = " ".join(set(obj[YML.snippet]))
        obj[YML.cmake_args] = " ".join(set(obj[YML.cmake_args]))
        obj[YML.artifact_name] = " ".join(set(obj[YML.artifact_name]))
        builds.append(obj)
        
    build_cmds = []

    for i, build in enumerate(builds):
        print(f"Processing build {i}: {build}")
        # print(build[YML.shield])
        build_cmds.append(" ".join([
        
            "just",
            "generic-build",
                build[YML.board],
                build[YML.shield],
                build[YML.snippet],
                build[YML.cmake_args],
                build[YML.artifact_name],]
                )
                )
        # just(
        #     [
        #         "generic-build",
        #         build[YML.board],
        #         build[YML.shield],
        #         build[YML.snippet],
        #         build[YML.cmake_args],
        #         build[YML.artifact_name],
        #     ],
        #     _fg=True,
        # )
    print("All build commands:")
    print("\n".join(build_cmds))



if __name__ == "__main__":
    main()
