load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_path", "GoLibrary", "GoSource", "GoPath", "go_context")
load("@co_znly_rules_gomobile//:common.bzl", "pkg_short", "genpath", "run_ex")

SUPPORT_FILES_JAVA = [
    "go/error.java",
    "go/LoadJNI.java",
    "go/Seq.java",
    "go/Universe.java",
]

SUPPORT_FILES_CC = [
    "java_universe.c",
    "seq_android.c",
    "seq.h",
    "universe.h",
]

SUPPORT_FILES_GO = [
    "seq_android.go",
]

def _gen_filenames(library):
    pkg_short_ = pkg_short(library)
    return struct(
        library = library,
        pkg_short = pkg_short_,
        pkg_class_java = pkg_short_ + "/" + pkg_short_.title() + ".java",
        pkg_java_h = pkg_short_ + ".h",
        pkg_java_c = "java_" + pkg_short_ + ".c",
    )


def gobind_java(ctx, go, env, libraries, srcs):
    java_files = []
    cc_files = []
    go_files = []
    packages = [l.importpath for l in libraries]
    for library in libraries:
        files = _gen_filenames(library)
        for filename in [files.pkg_class_java]:
            java_files.append(go.actions.declare_file(genpath(ctx, "java", filename)))
    for filename in SUPPORT_FILES_JAVA:
        java_files.append(go.actions.declare_file(genpath(ctx, "java", filename)))
    for filename in SUPPORT_FILES_CC:
        cc_files.append(go.actions.declare_file(genpath(ctx, "java", filename)))
    for filename in SUPPORT_FILES_GO:
        go_files.append(go.actions.declare_file(genpath(ctx, "java", filename)))
    run_ex(ctx,
        inputs = srcs,
        outputs = java_files + cc_files + go_files,
        executable = ctx.executable._gobind,
        env = env,
        arguments = [
            "-lang", "java",
            "-outdir", "{}/{}".format(ctx.genfiles_dir.path, genpath(ctx, "java")),
        ] + packages,
    )
    return struct(
        java_files = depset(java_files),
        cc_files = depset(cc_files),
        go_files = depset(go_files),
    )
