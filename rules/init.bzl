load("@rules_python//python:pip.bzl", "pip_parse")

def file_init():
    pip_parse(
        name = "rules_file_pip",
        python_interpreter_target = "@python_3_11_host//:python",
        requirements_lock = "@rules_file//:requirements.txt",
    )
