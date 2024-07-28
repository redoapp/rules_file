__package__ = "rulesfile.generateargs"

from argparse import ArgumentParser
from os.path import getsize


def args(str):
    return str.split("=", 1)


parser = ArgumentParser(prog="generate-args")
parser.add_argument("--output", default="/dev/stdout")
parser.add_argument(
    "args",
    help="file=arg1=arg2",
    nargs="*",
    type=args,
)

args = parser.parse_args()

with open(args.output, "w") as output:
    for file, *args in args.args:
        if args and getsize(file):
            for arg in args:
                print(arg, file=output)
