from pathlib import Path
from os import walk


def find_packages(root, roots, prefix):
    for root_dir in roots:
        for package in sorted(_packages(root / root_dir), key=str):
            package = package.relative_to(root)
            print(
                prefix
                if str(package) == "."
                else f"{prefix}/{package}"
                if prefix
                else package
            )


# https://github.com/bazelbuild/bazel/blob/4c2d91e762ab6e492853b021408129dd93fb5904/src/main/java/com/google/devtools/build/lib/skyframe/BazelSkyframeExecutorConstants.java#L30
# case-insensitive, have seen that matter
_build_names = {name.lower() for name in ("BUILD", "BUILD.bazel")}


def _packages(root):
    for dir_, _, files in walk(root):
        if any(file.lower() in _build_names for file in files):
            yield Path(dir_)
