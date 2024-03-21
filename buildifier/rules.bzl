load("//generate:providers.bzl", "FormatterInfo")

def _buildifier_format(ctx, path, src, out, bin):
    ctx.actions.run_shell(
        command = 'cp "$2" "$3" && "$1" "$3"',
        arguments = [bin.executable.path, src.path, out.path],
        inputs = [src],
        outputs = [out],
        tools = [bin],
    )

def _buildifier_impl(ctx):
    buildifier = ctx.toolchains[":toolchain_type"]

    bin = buildifier.buildifier

    def format(ctx, path, src, out):
        _buildifier_format(ctx, path, src, out, bin.files_to_run)

    format_info = FormatterInfo(
        fn = format,
    )

    default_info = DefaultInfo(files = depset(transitive = [bin.files]))

    return [default_info, format_info]

buildifier = rule(
    implementation = _buildifier_impl,
    toolchains = [":toolchain_type"],
)

def _buildifier_toolchain_impl(ctx):
    buildifier_default = ctx.attr.buildifier[DefaultInfo]

    toolchain_info = platform_common.ToolchainInfo(
        buildifier = buildifier_default,
    )

    return [toolchain_info]

buildifier_toolchain = rule(
    implementation = _buildifier_toolchain_impl,
    attrs = {
        "buildifier": attr.label(cfg = "target", executable = True, mandatory = True),
    },
)
