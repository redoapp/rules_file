load("@bazel_skylib//lib:shell.bzl", "shell")

def _refetch_impl(ctx):
    actions = ctx.actions
    repositories = ctx.attr.repositories
    template = ctx.attr._runner
    name = ctx.attr.name
    runner = ctx.file._runner
    workspace = ctx.workspace_name

    executable = actions.declare_file(name)
    actions.expand_template(
        output = executable,
        substitutions = {
            "%{repositories}": " ".join([shell.quote(repository) for repository in repositories]),
        },
        template = runner,
    )

    default_info = DefaultInfo(executable = executable)

    return [default_info]

refetch = rule(
    attrs = {
        "repositories": attr.string_list(),
        "_runner": attr.label(
            allow_single_file = True,
            default = "refetch-runner.sh.tpl",
        ),
    },
    executable = True,
    implementation = _refetch_impl,
)
