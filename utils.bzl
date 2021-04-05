load("@bazel_skylib//lib:paths.bzl", "paths")

def _pkg_short(importpath):
    return importpath.split("/")[-1]

def _slug(*args, token = "."):
    return token.join(args)

def _run_ex(ctx, executable, env = None, tools = None, **kwargs):
    env = env or {}
    tools = tools or []
    exports = " && ".join(["export %s=\"%s\"" % (k, v) for k, v in env.items()])
    command = exports + " && " + executable.path + " $@"
    return ctx.actions.run_shell(
        command = command,
        tools = tools + [executable],
        **kwargs
    )

def _touch(ctx, *args, **kwargs):
    f = ctx.actions.declare_file(*args, **kwargs)
    ctx.actions.write(f, content = "")
    return f

utils = struct(
    pkg_short = _pkg_short,
    run_ex = _run_ex,
    slug = _slug,
    touch = _touch,
)
