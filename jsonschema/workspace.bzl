load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(":jsonschema.bzl", JSONSCHEMA_VERSIONS = "VERSIONS")

def jsonschema_archive(name, sha256, strip_prefix, url):
    http_archive(
        name = name,
        build_file = Label("jsonschema.BUILD.bazel"),
        sha256 = sha256,
        strip_prefix = strip_prefix,
        url = url,
    )

def jsonschema_repositories(version = "12.10.1"):
    for platform, info in JSONSCHEMA_VERSIONS[version].items():
        jsonschema_archive(
            name = "jsonschema_%s" % platform.replace("-", "_"),
            sha256 = info.sha256,
            strip_prefix = info.prefix,
            url = info.url,
        )

def jsonschema_toolchains():
    native.register_toolchains(
        str(Label(":linux_amd64_toolchain")),
        str(Label(":linux_arm64_toolchain")),
        str(Label(":macos_amd64_toolchain")),
        str(Label(":macos_arm64_toolchain")),
    )
