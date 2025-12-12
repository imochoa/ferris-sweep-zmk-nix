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

# import sys
# import shutil
# import tempfile
import os
from pathlib import Path
import yaml

# import json
import sh

from sh import podman
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

    for i, build in enumerate(builds):
        print(f"Processing build {i}: {build}")
        just(
            [
                "generic-build",
                build[YML.board],
                build[YML.shield],
                build[YML.snippet],
                build[YML.cmake_args],
                build[YML.artifact_name],
            ],
            _fg=True,
        )

    #     https://v0-3-branch.zmk.dev/docs/development/module-creation
    #     https://v0-3-branch.zmk.dev/docs/development/local-toolchain/build-flash#building-with-external-modules
    #     # Check if this is a module-based config
    #     base_dir = "/tmp/zmk-build"
    #     if (workspace_dir / "zephyr" / "module.yml").exists():
    #         print("Detected zephyr module, using isolated directory")
    #         extra_cmake_args += " -DZMK_EXTRA_MODULES='/workspace'"
    #         base_dir = "/tmp/zmk-config"
    #
    #     try:
    #         # Run the build in the ZMK container
    #         run_container_build(
    #             container_cmd=container_cmd,
    #             workspace_dir=workspace_dir,
    #             build_dir=build_dir,
    #             base_dir=base_dir,
    #             config_path=config_path,
    #             board=board,
    #             extra_west_args=extra_west_args,
    #             extra_cmake_args=extra_cmake_args,
    #             cmake_args=cmake_args,
    #         )


if __name__ == "__main__":
    main()
