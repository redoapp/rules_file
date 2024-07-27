from rules_python.python.runfiles import runfiles
import sys

r = runfiles.Create()


def main(args):
    print("Differences detected")
    difference = False
    for diff in args.diffs:
        diff = r.Rlocation(diff)
        with open(diff, "r") as f:
            print(f.read())
    sys.exit(1)
