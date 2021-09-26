def gen_include_path(gobind_gen, lang):
    return "$(GENDIR)/{}/{}".format(gobind_gen, lang)

def genpath(ctx, *args):
    return "/".join((ctx.label.name,) + args)

def pkg_short(importpath):
    return importpath.split("/")[-1]

def slug(*args, token = "."):
    return token.join(args)

def run_ex(ctx, executable, gomobile, gobind, env = None, tools = None, **kwargs):
    """Runs executable to generate."""
    if not env:
        env = {}

    env = env or {}
    tools = tools or []
    command = " && ".join(
        ["export %s=\"%s\"" % (k, v) for k, v in env.items()] + 
        [executable.path + " $@"]
    )
    # command = exports + " && " + 
    # return ctx.actions.run_shell(
    #     command = command,
    #     tools = tools + [executable],
    #     **kwargs
    # )
    new_env = {
        str(k): str(v)
        for k, v in env.items()
    }
    # print("kwargs: ", kwargs)

    return ctx.actions.run_shell(
        command = command,
        tools = tools + [executable],
        env = new_env,
        **kwargs
    )