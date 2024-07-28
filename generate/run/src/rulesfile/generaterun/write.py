from os import chmod, makedirs, remove, stat
from os.path import dirname, join
from shutil import copy, copytree
from stat import S_ISDIR
from rules_python.python.runfiles import runfiles

r = runfiles.Create()


def main(args):
    for [src, out, diff] in args.files:
        # check diff
        diff = r.Rlocation(diff)

        print(src)

        # remove src
        try:
            src_stat = stat(src)
        except FileNotFoundError:
            pass
        else:
            if S_ISDIR(src_stat.st_mode):
                shutil.rmtree(src)
            else:
                remove(src)

        if not out:
            continue

        # copy out to src
        dir = dirname(src)
        if dir:
            makedirs(dirname(src), exist_ok=True)
        out = r.Rlocation(out)
        out_stat = stat(out)
        if S_ISDIR(out_stat.st_mode):
            copytree(out, src, copy_function=copy)
            chmod(src, args.dir_mode)
            for dirpath, dirnames, filenames in os.walk(src):
                for dirname_ in dirnames:
                    chmod(join(dirpath, dirname_), args.dir_mode)
                for filename in filenames:
                    chmod(join(dirpath, filename), args.file_mode)
        else:
            copy(out, src)
            chmod(src, args.file_mode)
