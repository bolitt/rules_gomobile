load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_path", "GoLibrary", "GoSource", "GoPath", "go_context")
load("@co_znly_rules_gomobile//:common.bzl", "pkg_short", "genpath", "run_ex")

SUPPORT_FILES_OBJC = [
    "seq_darwin.go",
    "seq_darwin.m",
    "seq.h",
    "universe.h",
    "Universe.m",
    "Universe.objc.h",
]

SUPPORT_FILES_GO = [
    "seq_darwin.go",
]

PUBLIC_OBJC_HDRS = [
    "ref.h",
    "Universe.objc.h",
]

def _gen_filenames(library):
    pkg_short_ = pkg_short(library)
    return struct(
        library = library,
        pkg_short = pkg_short_,
        objc_h = pkg_short_.title() + ".objc.h",
        objc_m = pkg_short_.title() + ".m",
        main_h = pkg_short_ + ".h",
    )

def gobind_objc(ctx, go, env, libraries, srcs):
    objc_hdrs = []
    objc_files = []
    go_files = []
    packages = [l.importpath for l in libraries]
    for library in libraries:
        files = _gen_filenames(library)
        objc_hdrs.append(go.actions.declare_file(genpath(ctx, "objc", files.objc_h)))
        for filename in [files.objc_m, files.main_h]:
            objc_files.append(go.actions.declare_file(genpath(ctx, "objc", filename)))
    for filename in PUBLIC_OBJC_HDRS:
        objc_hdrs.append(go.actions.declare_file(genpath(ctx, "objc", filename)))
    for filename in SUPPORT_FILES_OBJC:
        objc_files.append(go.actions.declare_file(genpath(ctx, "objc", filename)))
    for filename in SUPPORT_FILES_OBJC:
        objc_files.append(go.actions.declare_file(genpath(ctx, "objc", filename)))
    for filename in SUPPORT_FILES_GO:
        go_files.append(go.actions.declare_file(genpath(ctx, "objc", filename)))

    run_ex(ctx,
        inputs = srcs,
        outputs = objc_hdrs + objc_files,
        executable = ctx.executable._gobind,
        env = env,
        arguments = [
            "-lang", "objc",
            "-outdir", ctx.genfiles_dir.path + "/" + genpath(ctx, "objc"),
        ] + packages,
    )

    return struct(
        objc_hdrs = depset(objc_hdrs),
        objc_files = depset(objc_files),
        go_files = depset(go_files),
    )
