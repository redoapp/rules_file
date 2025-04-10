load("@bazel_skylib//lib:shell.bzl", "shell")
load("//util:path.bzl", "output_name", "runfile_path")
load(":providers.bzl", "FormatterInfo")
load(":runner.bzl", "create_runner")

def _format_impl(ctx):
    actions = ctx.actions
    args_default = ctx.attr._args[DefaultInfo]
    bash_runfiles = ctx.files._bash_runfiles
    diff = ctx.attr._diff[DefaultInfo]
    dir_mode = ctx.attr.dir_mode
    file_mode = ctx.attr.file_mode
    formatter = ctx.attr.formatter[FormatterInfo]
    label = ctx.label
    name = ctx.attr.name
    run = ctx.attr._run[DefaultInfo]
    runner = ctx.file._runner
    prefix = ctx.attr.prefix
    strip_prefix = ctx.attr.strip_prefix
    srcs = ctx.files.srcs
    workspace_name = ctx.workspace_name

    file_defs = {}
    for src in srcs:
        path = output_name(file = src, label = ctx.label, prefix = prefix, strip_prefix = strip_prefix)
        formatted = actions.declare_file("%s.out/%s" % (name, src.path))
        formatter.fn(ctx, path, src, formatted)
        file_defs[path] = struct(generated = formatted, src = src)

    bin = ctx.actions.declare_file(name)

    default_info = create_runner(
        actions = actions,
        args_bin = args_default,
        bash_runfiles = bash_runfiles,
        bin = bin,
        diff_bin = diff,
        dir_mode = dir_mode,
        file_defs = file_defs,
        file_mode = file_mode,
        label = label,
        name = name,
        run_bin = run,
        runfiles_fn = ctx.runfiles,
        runner_template = runner,
        workspace_name = workspace_name,
    )

    return [default_info]

format = rule(
    attrs = {
        "formatter": attr.label(
            mandatory = True,
            providers = [FormatterInfo],
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Sources",
        ),
        "file_mode": attr.string(
            default = "664",
        ),
        "dir_mode": attr.string(
            default = "775",
        ),
        "strip_prefix": attr.string(),
        "prefix": attr.string(),
        "_args": attr.label(
            cfg = "exec",
            default = "//generate/args:bin",
            executable = True,
        ),
        "_bash_runfiles": attr.label(
            allow_files = True,
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_diff": attr.label(
            cfg = "exec",
            default = "//generate/diff:bin",
            executable = True,
        ),
        "_run": attr.label(
            default = "//generate/run:bin",
            cfg = "target",
            executable = True,
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = "runner.sh.tpl",
        ),
    },
    executable = True,
    implementation = _format_impl,
)

def _formatter_composite_impl(ctx):
    formatters = [target[FormatterInfo] for target in ctx.attr.formatters]
    fns = [formatter.fn for formatter in formatters]

    def _fn(ctx, path, src, formatted):
        actions = ctx.actions
        name = ctx.attr.name
        for i, fn in enumerate(fns):
            tmp = formatted if i == len(fns) - 1 else actions.declare_file("%s.out.%s/%s" % (name, i + 1, src.path))
            fn(ctx, path, src, tmp)
            src = tmp

    formatter_info = FormatterInfo(fn = _fn)

    return [formatter_info]

formatter_composite = rule(
    attrs = {
        "formatters": attr.label_list(mandatory = True, providers = [FormatterInfo]),
    },
    implementation = _formatter_composite_impl,
    provides = [FormatterInfo],
)

def _generate_impl(ctx):
    actions = ctx.actions
    args_default = ctx.attr._args[DefaultInfo]
    bash_runfiles = ctx.files._bash_runfiles
    data = ctx.files.data
    data_prefix = (
        ctx.attr.data_prefix[len("/"):] if ctx.attr.data_prefix.startswith("/") else ctx.attr.data_prefix if not ctx.label.package else ctx.label.package if not ctx.attr.data_prefix else "%s/%s" % (ctx.label.package, ctx.attr.data_prefix)
    )
    data_strip_prefix = ctx.attr.data_strip_prefix
    diff = ctx.attr._diff[DefaultInfo]
    dir_mode = ctx.attr.dir_mode
    file_mode = ctx.attr.file_mode
    label = ctx.label
    name = ctx.attr.name
    run = ctx.attr._run[DefaultInfo]
    runner = ctx.file._runner
    src_prefix = (
        ctx.attr.src_prefix[len("/"):] if ctx.attr.src_prefix.startswith("/") else ctx.attr.src_prefix if not ctx.label.package else ctx.label.package if not ctx.attr.src_prefix else "%s/%s" % (ctx.label.package, ctx.attr.src_prefix)
    )
    src_strip_prefix = ctx.attr.src_strip_prefix
    srcs = ctx.files.srcs
    workspace_name = ctx.workspace_name

    file_defs = {}
    for src in srcs:
        path = output_name(file = src, label = label, prefix = src_prefix, strip_prefix = src_strip_prefix)
        file_defs[path] = struct(src = src, generated = None)
    for datum in data:
        path = output_name(file = datum, label = label, prefix = data_prefix, strip_prefix = data_strip_prefix)
        if path in file_defs:
            file_defs[path] = struct(src = file_defs[path].src, generated = datum)
        else:
            file_defs[path] = struct(src = None, generated = datum)

    bin = ctx.actions.declare_file(name)
    default_info = create_runner(
        actions = actions,
        args_bin = args_default,
        bash_runfiles = bash_runfiles,
        bin = bin,
        diff_bin = diff,
        dir_mode = dir_mode,
        file_defs = file_defs,
        file_mode = file_mode,
        label = label,
        name = name,
        run_bin = run,
        runfiles_fn = ctx.runfiles,
        runner_template = runner,
        workspace_name = workspace_name,
    )

    return [default_info]

generate = rule(
    attrs = {
        "data_prefix": attr.string(
            doc = "Package-relative prefix to add",
        ),
        "data_strip_prefix": attr.string(
            doc = "Package-relative prefix to remove",
        ),
        "data": attr.label_list(
            allow_files = True,
        ),
        "src_prefix": attr.string(),
        "src_strip_prefix": attr.string(),
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "file_mode": attr.string(
            default = "664",
        ),
        "dir_mode": attr.string(
            default = "775",
        ),
        "_args": attr.label(
            cfg = "exec",
            default = "//generate/args:bin",
            executable = True,
        ),
        "_bash_runfiles": attr.label(
            allow_files = True,
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_diff": attr.label(
            cfg = "exec",
            default = "//generate/diff:bin",
            executable = True,
        ),
        "_run": attr.label(
            default = "//generate/run:bin",
            cfg = "target",
            executable = True,
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = ":runner",
        ),
    },
    executable = True,
    implementation = _generate_impl,
)

def _multi_generate_impl(ctx):
    actions = ctx.actions
    bash_runfiles = ctx.files._bash_runfiles
    deps = [target[DefaultInfo] for target in ctx.attr.deps]
    name = ctx.attr.name
    runner = ctx.file._runner
    workspace_name = ctx.workspace_name

    runfiles = ctx.runfiles(files = bash_runfiles)
    runfiles = runfiles.merge_all([dep.default_runfiles for dep in deps])

    bin = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        template = runner,
        output = bin,
        substitutions = {
            "%{formats}": " ".join([
                shell.quote(runfile_path(workspace_name, dep.files_to_run.executable))
                for dep in deps
            ]),
        },
    )

    default_info = DefaultInfo(
        runfiles = runfiles,
        executable = bin,
    )

    return [default_info]

multi_generate = rule(
    attrs = {
        "deps": attr.label_list(),
        "_bash_runfiles": attr.label(
            allow_files = True,
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = ":multi_runner",
        ),
    },
    doc = "Combine multiple generators",
    implementation = _multi_generate_impl,
    executable = True,
)

def _generate_test_impl(ctx):
    actions = ctx.actions
    bash_runfiles = ctx.files._bash_runfiles
    generate_info = ctx.attr.generate[DefaultInfo]
    name = ctx.attr.name
    tester = ctx.file._tester
    workspace_name = ctx.workspace_name

    bin = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        template = tester,
        output = bin,
        substitutions = {
            "%{bin}": shell.quote(runfile_path(workspace_name, generate_info.files_to_run.executable)),
        },
    )

    runfiles = ctx.runfiles(files = bash_runfiles)
    runfiles = runfiles.merge(generate_info.default_runfiles)

    default_info = DefaultInfo(
        executable = bin,
        runfiles = runfiles,
    )

    return [default_info]

generate_test = rule(
    attrs = {
        "generate": attr.label(
            cfg = "target",
            executable = True,
            mandatory = True,
        ),
        "_bash_runfiles": attr.label(
            allow_files = True,
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_tester": attr.label(
            allow_single_file = True,
            default = ":tester",
        ),
    },
    implementation = _generate_test_impl,
    test = True,
)
