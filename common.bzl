def gen_include_path(gobind_gen, lang):
    return "$(GENDIR)/{}/{}".format(gobind_gen, lang)

def genpath(ctx, lang, filename = ""):
    return ctx.label.name + "/" + lang + "/" + filename

def pkg_short(library):
    return library.importpath.split("/")[-1]

def slug(name, slug, token="."):
    return name + token + slug
