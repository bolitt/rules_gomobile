def gen_include_path(gobind_gen, lang):
    return "$(GENDIR)/{}/{}".format(gobind_gen, lang)

def genpath(ctx, *args):
    return "/".join((ctx.label.name,) + args)

def pkg_short(importpath):
    return importpath.split("/")[-1]

def slug(*args, token="."):
    return token.join(args)

def run_ex(ctx, env=None, executable=None, arguments=None, **kwargs):
    exports = " && ".join(["export %s=\"%s\"" % (k, v) for k, v in env.items()])
    command = exports + " && " + executable.path + " $@"
    kwargs.update({
        "inputs": kwargs.get("inputs", []) + [executable],
    })
    return ctx.actions.run_shell(
        command = command,
        arguments = arguments,
        **kwargs
    )
