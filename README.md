# rules_file

Bazel rules for basic file operations, such as creating directories and formatting.

## Directory

Create a directory from files:

```bzl
load("@rules_file//file:rules.bzl", "directory")

directory(
    name = "example",
    srcs = glob(["**/*.txt"]),
)
```

Create a directory from a tarball:

```bzl
load("@rules_file//file:rules.bzl", "untar")

untar(
    name = "example",
    src = "example.tar",
)
```

## Package-less Files

Access files without regard to package structure. This can be helpful for formatting or Bazel integration tests.

### Workspace Example

Create a new repository containing all workspace files.

**WORKSPACE.bazel**

```bzl
files(
    name = "files"
    build = "BUILD.file.bazel",
    root_file = "//:WORKSPACE.bazel",
)
```

**BAZEL.bazel**

```
load("@rules_file//file:rules.bzl", "bazelrc_deleted_packages")

bazelrc_deleted_packages(
    name = "bazelrc",
    output = "deleted_packages.bazelrc",
    packages = ["@files//:packages"],
)
```

**files.bazel**

```bzl
# note: files is the symlink to the workspace
filegroup(
    name = "example",
    srcs = glob(["files/**/*.txt"]),
    visibility = ["//visibility:public"],
)
```

Generate deleted_packages.bazelrc:

```
bazel run :bazelrc
```

(To check if this is up-to-date, run `bazel run :bazelrc.diff`.)

**.bazelrc**

```
import %workspace%/deleted.bazelrc
```

Now `@files//:example` is all \*.txt files in the workspace.

### Bazel Integration Test Example

Use files in the test directory as data for a Bazel integration test.

**BAZEL.bazel**

```
load("@rules_file//file:rules.bzl", "bazelrc_deleted_packages", "find_packages")

filegroup(
    name = "test",
    srcs = glob(["test/**/*.bazel" "test/**/*.txt"]),
)

find_packages(
    name = "test_packages",
    roots = ["test"],
)

bazelrc_deleted_packages(
    name = "bazelrc",
    output = "deleted_packages.bazelrc",
    packages = [":test_packages"],
)
```

Generate `deleted_packages.bazelrc` by running:

```
bazel run :bazelrc
```

**.bazelrc**

```
import %workspace%/deleted_packages.bazelrc
```

## Generate

In some cases, it is necessary to version control build products in the workspace (bootstrapping, working with other tools).

These rules build the outputs, and copy them to the workspace or check for differences.

**BUILD.bazel**

```bzl
load("@rules_file//file:rules.bzl", "bazelrc_deleted_packages")
load("@rules_file//file:rules.bzl", "generate", "generate_test")

genrule(
    name = "example",
    cmd = "echo GENERATED! > $@",
    outs = ["out/example.txt"],
)

generate(
    name = "example_gen",
    srcs = "example.txt",
    data = ["out/example.txt"],
    data_strip_prefix = "out",
)

generate_test(
    name = "example_diff",
    generate = ":example_gen",
)

bazelrc_deleted_packages(
    name = "gen_bazelrc",
    output = "deleted.bazelrc",
    packages = ["@files//:packages"],
)
```



To overwrite the workspace file:

```bzl
bazel run :example_gen
```

To check for differences (e.g. in CI):

```bzl
bazel test :example_diff
```

## Format

Formatting is a particular case of the checked-in build products pattern.

The code formatting is a regular Bazel action. The formatted result can be using to overwrite workspace files, or to check for differences.

This repository has rules for buildifier, black, and gofmt. It is also used for [prettier](https://github.com/rivethealth/rules_javascript).

### Buildifier Example

**WORKSPACE.bazel**

```bzl
load("@rules_file//buildifier:workspace.bzl", "buildifier_repositories", "buildifier_toolchains")

buildifier_repositories()

buildifier_toolchains()

files(
    name = "files"
    build = "BUILD.file.bazel",
    root_file = "//:WORKSPACE.bazel",
)
```

The `@rules_file//buildifier:toolchain_type` toolchain will download a
pre-build executable of buildifier, if it exists. Otherwise, it will rely on the
`@com_github_bazelbuild_buildtools` repo to build from source.

**BUILD.bazel**

```bzl
load("@rules_file//generate:rules.bzl", "format", "generate_test")

format(
    name = "buildifier_format",
    srcs = ["@files//:buildifier_files"],
    formatter = "@rules_file//buildifier",
    strip_prefix = "files",
)

generate_test(
    name = "buildifier_diff",
    generate = ":format",
)
```

**files.bazel**

```bzl
filegroup(
    name = "buildifier_files",
    srcs = glob(
        [
            "files/**/*.bazel",
            "files/**/*.bzl",
            "files/**/BUILD",
            "files/**/WORKSPACE",
        ],
    ),
    visibility = ["//visibility:public"],
)
```

Generate deleted_packages.bazelrc:

```
bazel run :gen_bazelrc
```

**.bazelrc**

```
import %workspace%/deleted_packages.bazelrc
```

To format:

```sh
bazel run :buildifier_format
```

To check format:

```sh
bazel run :buildifier_diff
```
