def gen_include_path(gobind_gen, lang):
    return "$(GENDIR)/{}/{}".format(gobind_gen, lang)

def genpath(ctx, *args):
    return "/".join((ctx.label.name,) + args)

def pkg_short(importpath):
    return importpath.split("/")[-1]

def slug(*args, token = "."):
    return token.join(args)

def run_ex(ctx, executable, env = None, tools = None, **kwargs):
    env = env or {}
    tools = tools or []
    exports = " && ".join(["export %s=\"%s\"" % (k, v) for k, v in env.items()])
    command = exports + " && " + executable.path + " $@"
    return ctx.actions.run_shell(
        command = command,
        tools = tools + [executable],
        **kwargs
    )
