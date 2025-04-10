load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load(":buildifier.bzl", "BUILDIFIER_REPOS")

def buildifier_repositories(version = "v8.0.3"):
    for name, info in BUILDIFIER_REPOS[version].items():
        http_file(
            name = "buildifier_%s" % name,
            executable = True,
            sha256 = info.sha256,
            url = "https://github.com/bazelbuild/buildtools/releases/download/%s/%s" % (version, info.path),
        )

def buildifier_toolchains():
    native.register_toolchains(
        "@rules_file//buildifier:macos_amd64_toolchain",
        "@rules_file//buildifier:macos_arm64_toolchain",
        "@rules_file//buildifier:linux_amd64_toolchain",
        "@rules_file//buildifier:linux_arm64_toolchain",
        "@rules_file//buildifier:windows_amd64_toolchain",
        "@rules_file//buildifier:src_toolchain",
    )
