def join(*paths, seperator="@"):
    """Join with @."""
    non_empty = []
    for p in paths:
        non_empty.append(p)
    return seperator.join(non_empty)


def run_executable(ctx, executable, gomobile, env = None, tools = None, jdk_path=None, **kwargs):
    """Runs executable to generate."""
    env = env or {}
    tools = tools or []

    exports = [
        "export {}=\"{}\"".format(k, v) for k, v in env.items()
    ] + [
        # Expose JAVA_HOME from "${word_dir}/external/local_jdk".
        # Binary java is at "${JAVA_HOME}/bin/java".
        "export JAVA_HOME=\"`pwd`/{}\"".format(jdk_path)
    ]
    checks = [
        # Checks whether java exists.
        """ if [[ ! -e "${JAVA_HOME}/bin/java" ]]; then echo "java not found: ${JAVA_HOME}/bin/java"; exit 1; fi """,
        # Checks whether javac exists.
        """ if [[ ! -e "${JAVA_HOME}/bin/javac" ]]; then echo "javac not found: ${JAVA_HOME}/bin/javac"; exit 1; fi """,
    ]
    exes = [
        "{} $@".format(executable.path)
    ]

    # command should be one-line command. run_shell runs:
    # bash -c <command> "" <arguments>
    command = " && ".join(exports + checks + exes)

    env_in_strings = {
        str(k): str(v)
        for k, v in env.items()
    }

    # run_shell: https://docs.bazel.build/versions/main/skylark/lib/actions.html#run_shell
    return ctx.actions.run_shell(
        command = command,
        tools = tools + [executable],
        env = env_in_strings,
        **kwargs
    )