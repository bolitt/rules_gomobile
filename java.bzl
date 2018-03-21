load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_path", "GoLibrary", "GoSource", "GoPath", "go_context")
load("@co_znly_rules_gomobile//:common.bzl", "pkg_short", "genpath", "run_ex")

SUPPORT_FILES_JAVA = [
    "go/error.java",
    "go/LoadJNI.java",
    "go/Seq.java",
    "go/Universe.java",
]

SUPPORT_FILES_CC = [
    "universe_android.c",
    "universe_android.h",
    "seq_android.c",
    "seq_android.h",
]

SUPPORT_FILES_GO = [
    "seq_android.go",
]

def _gen_filenames(library):
    pkg_short_ = pkg_short(library)
    pkg_short_title = pkg_short.title()
    return struct(
        library = library,
        pkg_short = pkg_short_,
        hdr = pkg_short_ + ".h",
        android_hdr = pkg_short_ + "_android.h",
        android_c = pkg_short_ + "_android.c",
        android_class = pkg_short_ + "/" + pkg_short_title + ".java",
        darwin_hdr = pkg_short_ + "_darwin.h",
        darwin_m = pkg_short_title + "_darwin.m",
        darwin_public_hdr = pkg_short_title + ".objc.h",
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
        for filename in [files.pkg_java_h, files.pkg_java_c]:
            cc_files.append(go.actions.declare_file(genpath(ctx, "java", filename)))
    for filename in SUPPORT_FILES_JAVA:
        java_files.append(go.actions.declare_file(genpath(ctx, "java", filename)))
    for filename in SUPPORT_FILES_CC:
        cc_files.append(go.actions.declare_file(genpath(ctx, "java", filename)))
    for filename in SUPPORT_FILES_GO:
        go_files.append(go.actions.declare_file(genpath(ctx, "java", filename)))

    return struct(
        java_files = depset(java_files),
        cc_files = depset(cc_files),
        go_files = depset(go_files),
    )
