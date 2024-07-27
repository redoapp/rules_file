load("@bazel_skylib//lib:shell.bzl", "shell")
load("//util:path.bzl", "runfile_path")

def create_runner(runfiles_fn, name, bash_runfiles, actions, bin, diff_bin, dir_mode, file_mode, label, run_bin, runner_template, file_defs, workspace_name):
    arg_files = []
    diffs = []
    for path, file_def in file_defs.items():
        diff = actions.declare_file("%s.diff/%s.patch" % (name, path))
        args = actions.args()
        args.add(file_def.src.path if file_def.src else "")
        args.add(file_def.generated.path if file_def.generated else "")
        args.add(diff)
        actions.run(
            arguments = [args],
            executable = diff_bin.files_to_run.executable,
            inputs = ([file_def.src] if file_def.src else []) + ([file_def.generated] if file_def.generated else []),
            mnemonic = "Diff",
            outputs = [diff],
            progress_message = "Diffing %{output}",
            tools = [diff_bin.files_to_run],
        )
        diffs.append(diff)

        check_args_file = actions.declare_file("%s.check/%s.args" % (name, path))
        args = actions.args()
        args.add(diff)
        args.add(runfile_path(workspace_name, diff))
        args.add(check_args_file)
        actions.run_shell(
            arguments = [args],
            command = '([ ! -s "$1" ] || echo "$2") > "$3"',
            execution_requirements = {"no-cache": "1"},
            inputs = [diff],
            mnemonic = "GenerateArgs",
            outputs = [check_args_file],
            progress_message = "Writing generate args for %{input}",
        )

        write_args_file = actions.declare_file("%s.write/%s.args" % (name, path))
        args = actions.args()
        args.add(diff)
        args.add("\n".join([
            "--file",
            path,
            runfile_path(workspace_name, file_def.generated) if file_def.generated else "",
            runfile_path(workspace_name, diff),
        ]))
        args.add(write_args_file)
        actions.run_shell(
            arguments = [args],
            command = '([ ! -s "$1" ] || echo "$2") > "$3"',
            execution_requirements = {"no-cache": "1"},
            inputs = [diff],
            mnemonic = "GenerateArgs",
            outputs = [write_args_file],
            progress_message = "Writing generate args for %{input}",
        )

        arg_files.append(struct(check = check_args_file, write = write_args_file))

    check_args_file = actions.declare_file("%s.check.args" % name)
    _concat(
        actions = actions,
        files = [arg_file.check for arg_file in arg_files],
        output = check_args_file,
        prefix = "%s.check-" % name,
    )

    write_args_file = actions.declare_file("%s.write.args" % name)
    _concat(
        actions = actions,
        files = [arg_file.write for arg_file in arg_files],
        output = write_args_file,
        prefix = "%s.write-" % name,
    )

    bin = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        template = runner_template,
        output = bin,
        substitutions = {
            "%{check_args}": shell.quote(runfile_path(workspace_name, check_args_file)),
            "%{dir_mode}": shell.quote(dir_mode),
            "%{label}": shell.quote(str(label)),
            "%{file_mode}": shell.quote(file_mode),
            "%{write_args}": shell.quote(runfile_path(workspace_name, write_args_file)),
        },
    )

    generated = [file_def.generated for file_def in file_defs.values() if file_def.generated]

    runfiles = runfiles_fn(files = [check_args_file, write_args_file] + bash_runfiles + diffs + generated)
    runfiles = runfiles.merge(diff_bin.default_runfiles)

    # It seems that Python executable requires data_runfiles.
    # Otherwise, fails with error: Cannot find .runfiles directory
    runfiles = runfiles.merge(run_bin.data_runfiles)

    default_info = DefaultInfo(
        executable = bin,
        runfiles = runfiles,
    )

    return default_info

_BATCH = 100

def _concat(actions, prefix, files, output):
    if _BATCH <= len(files):
        parts = []
        for i in range(0, len(files), _BATCH):
            part = actions.declare_file("%s%s" % (prefix, i // _BATCH))
            args = actions.args()
            args.add(part)
            for file in files[i:i + _BATCH]:
                args.add(file)
            actions.run_shell(
                arguments = [args],
                command = 'out="$1" && shift && cat "$@" > "$out"',
                execution_requirements = {"no-cache": "1"},
                inputs = files[i:i + _BATCH],
                mnemonic = "Concat",
                outputs = [part],
                progress_message = "Concatenating %{output}",
            )
            parts.append(part)
        files = parts
    args = actions.args()
    args.add(output)
    for file in files:
        args.add(file)
    actions.run_shell(
        arguments = [args],
        command = 'out="$1" && shift && cat "$@" > "$out"',
        execution_requirements = {"no-cache": "1"},
        inputs = files,
        mnemonic = "Concat",
        outputs = [output],
        progress_message = "Concatenating %{output}",
    )
