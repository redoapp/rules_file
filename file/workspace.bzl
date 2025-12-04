_BUILD = """
load("@rules_file//file:rules.bzl", "find_packages")

find_packages(
    name = "packages",
    prefix = repository_name() + "//files",
    roots = [""],
    visibility = ["//visibility:public"],
)
"""

# Ideally, this would not have to nest the directory in a files/ directory, but
# https://github.com/bazelbuild/bazel/issues/16217 .
def _files_impl(ctx):
    ignores = ctx.attr.ignores

    ctx.file("WORKSPACE.bazel", executable = False)
    content = _BUILD
    content += ctx.read(ctx.attr.build)
    ctx.file("BUILD.bazel", content = content, executable = False)
    path = ctx.path(ctx.attr.root_file).dirname
    ignores = ignores + [
        "bazel-%s" % path.basename,
        "bazel-bin",
        "bazel-genrules",
        "bazel-out",
        "bazel-testlogs",
    ]
    ignores = ["files/%s" % ignore for ignore in ignores]
    ctx.file(".bazelignore", "\n".join(ignores))
    ctx.symlink(path, "files")

files = repository_rule(
    implementation = _files_impl,
    attrs = {
        "build": attr.label(
            allow_single_file = True,
        ),
        "ignores": attr.string_list(),
        "root_file": attr.label(
            doc = "A file in the root",
        ),
    },
    local = True,
)

def _ends_with_any(f, extensions):
    for ext in extensions:
        if f.endswith(ext):
            return True
    return False

_ESLINT_EXTENSIONS = [".js", ".cjs", ".mjs", ".jsx", ".ts", ".cts", ".mts", ".tsx"]
_PRETTIER_EXTENSIONS = [".js", ".cjs", ".mjs", ".jsx", ".ts", ".cts", ".mts", ".tsx", ".css", ".html", ".json", ".md", ".scss", ".sql", ".svg", ".xml", ".yml"]

def _diff_files_impl(ctx):
    ctx.get_env("BUILD_RANDOM")
    ignores = ctx.attr.ignores

    ctx.file("WORKSPACE.bazel", executable = False)

    # Get the workspace root directory
    path = ctx.path(ctx.attr.root_file).dirname

    # Get changed files from git (run in workspace directory)
    result = ctx.execute(["git", "diff", "--name-only", "main"], quiet = True, working_directory = str(path))
    if result.return_code != 0:
        # Fallback to origin/main
        result = ctx.execute(["git", "diff", "--name-only", "origin/main"], quiet = True, working_directory = str(path))

    changed_files = []
    if result.return_code == 0:
        changed_files = [f.strip() for f in result.stdout.split("\n") if f.strip()]

    # Filter out ignored paths
    filtered_files = []
    for f in changed_files:
        ignored = False
        for ignore in ignores:
            if f.startswith(ignore + "/") or f == ignore:
                ignored = True
                break
        if not ignored:
            filtered_files.append(f)

    # Symlink entire workspace (like @files does)
    ctx.symlink(path, "files")

    # Collect all directories that contain BUILD.bazel files
    # We need to ignore these to prevent subpackage detection
    dirs_with_build = {}
    for f in filtered_files:
        # Find directories containing BUILD files in the path
        parts = f.split("/")
        for i in range(len(parts)):
            dir_path = "/".join(parts[:i+1])
            dir_full = path.get_child(dir_path)
            if dir_full.exists:
                build_in_dir = path.get_child(dir_path + "/BUILD.bazel")
                if build_in_dir.exists:
                    dirs_with_build["files/" + dir_path] = True

    # Create .bazelignore to prevent subpackages from being recognized
    # The key is to ignore "files" itself since it contains a BUILD.bazel
    bazelignore_entries = ["files"] + ignores + [
        "bazel-%s" % path.basename,
        "bazel-bin",
        "bazel-genrules",
        "bazel-out",
        "bazel-testlogs",
    ]
    bazelignore_entries = ["files/%s" % ignore for ignore in bazelignore_entries[1:]]
    bazelignore_entries = ["files"] + bazelignore_entries  # Add "files" at the start
    # Add all directories containing BUILD files
    bazelignore_entries = bazelignore_entries + sorted(dirs_with_build.keys())
    ctx.file(".bazelignore", "\n".join(bazelignore_entries))

    # Categorize files by type - only include files that actually changed
    bazel_files = []
    black_files = []
    black_exec_files = []
    eslint_files = []
    prettier_files = []
    shfmt_files = []

    for f in filtered_files:
        # Check if file exists
        src = path.get_child(f)
        if not src.exists:
            continue

        prefixed = "files/" + f
        if f.endswith(".bazel") or f.endswith(".bzl"):
            bazel_files.append(prefixed)
        if f.endswith(".py"):
            black_files.append(prefixed)
        if f == "tools/bazel":
            black_exec_files.append(prefixed)
        if _ends_with_any(f, _ESLINT_EXTENSIONS):
            eslint_files.append(prefixed)
        if _ends_with_any(f, _PRETTIER_EXTENSIONS):
            prettier_files.append(prefixed)
        if f.endswith(".sh"):
            shfmt_files.append(prefixed)

    # Collect all files that need to be exported
    all_files = bazel_files + black_files + black_exec_files + eslint_files + prettier_files + shfmt_files

    # Deduplicate the list
    all_files_set = {}
    for f in all_files:
        all_files_set[f] = True
    all_files_unique = sorted(all_files_set.keys())

    # Write BUILD file with exports_files and categorized file lists
    content = 'package(default_visibility = ["//visibility:public"])\n\n'
    if all_files_unique:
        content += "exports_files(%s)\n\n" % repr(all_files_unique)
    content += "filegroup(name = \"bazel_files\", srcs = %s)\n" % repr(bazel_files)
    content += "filegroup(name = \"black_files\", srcs = %s)\n" % repr(black_files)
    content += "filegroup(name = \"black_exec_files\", srcs = %s)\n" % repr(black_exec_files)
    content += "filegroup(name = \"eslint_files\", srcs = %s)\n" % repr(eslint_files)
    content += "filegroup(name = \"prettier_files\", srcs = %s)\n" % repr(prettier_files)
    content += "filegroup(name = \"shfmt_files\", srcs = %s)\n" % repr(shfmt_files)
    content += "filegroup(name = \"shfmt_exec_files\", srcs = [])\n"
    ctx.file("BUILD.bazel", content = content, executable = False)

diff_files = repository_rule(
    implementation = _diff_files_impl,
    attrs = {
        "build": attr.label(
            allow_single_file = True,
        ),
        "ignores": attr.string_list(),
        "root_file": attr.label(
            doc = "A file in the root",
        ),
    },
    local = True,
    configure = True,  # Re-fetch when --configure is passed
)
