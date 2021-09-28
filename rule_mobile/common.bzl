def gen_include_path(gobind_gen, lang):
    return "$(GENDIR)/{}/{}".format(gobind_gen, lang)

def genpath(ctx, *args):
    return "/".join((ctx.label.name,) + args)

def pkg_short(importpath):
    return importpath.split("/")[-1]

def slug(*args, token = "."):
    return token.join(args)

def run_executable(ctx, executable, gomobile, env = None, tools = None, **kwargs):
    """Runs executable to generate."""
    if not env:
        env = {}

    env = env or {}
    tools = tools or []
    command = " && ".join(
        ["export %s=\"%s\"" % (k, v) for k, v in env.items()] + 
        [executable.path + " $@"]
    )
    
    env_in_strings = {
        str(k): str(v)
        for k, v in env.items()
    }
    return ctx.actions.run_shell(
        command = command,
        tools = tools + [executable],
        env = env_in_strings,
        **kwargs
    )