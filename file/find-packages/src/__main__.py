from argparse import ArgumentParser
from pathlib import Path
from os import walk

parser = ArgumentParser(prog="find-packages")
parser.add_argument("root", type=Path)
parser.add_argument("roots", nargs="*")
parser.add_argument("--prefix", default="")
args = parser.parse_args()

# https://github.com/bazelbuild/bazel/blob/4c2d91e762ab6e492853b021408129dd93fb5904/src/main/java/com/google/devtools/build/lib/skyframe/BazelSkyframeExecutorConstants.java#L30
# case-insensitive, have seen that matter
build_names = {name.lower() for name in ("BUILD", "BUILD.bazel")}


def packages(root):
    for root, _, files in walk(args.root / root):
        if any(file.lower() in build_names for file in files):
            yield Path(root).relative_to(args.root)


for root in args.roots:
    for package in sorted(packages(root), key=str):
        print(
            args.prefix
            if str(package) == "."
            else f"{args.prefix}/{package}" if args.prefix else package
        )
