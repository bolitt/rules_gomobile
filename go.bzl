load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_path", "GoLibrary", "GoSource", "GoPath", "go_context")
load("@co_znly_rules_gomobile//:common.bzl", "pkg_short", "genpath", "run_ex")

SUPPORT_FILES_GO = [
    "go_main.go",
    "seq.go",
]

MAIN_OBJC_GO = """\
package main

import (
    _ "gomobile_bind"
)

import "C"

func main() {}
"""

MAIN_JAVA_GO = """\
package main

import (
	_ "golang.org/x/mobile/bind/java"
    _ "gomobile_bind"
)

import "C"

func main() {}
"""

def _gen_filenames(library):
    pkg_short_ = pkg_short(library)
    return struct(
        library = library,
        pkg_short = pkg_short_,
        main_go = "go_" + pkg_short_ + "main.go",
    )

def gobind_go(ctx, go, env, libraries, srcs):
    objc_hdrs = []
    objc_files = []
    go_files = []
    packages = [l.importpath for l in libraries]
    for library in libraries:
        files = _gen_filenames(library)
        for filename in [files.main_go]:
            go_files.append(go.actions.declare_file(genpath(ctx, "go", filename)))
    for filename in SUPPORT_FILES_GO:
        go_files.append(go.actions.declare_file(genpath(ctx, "go", filename)))

    main_objc_go = go.actions.declare_file(genpath(ctx, "go", "main.objc.go"))
    go.actions.write(main_objc_go, MAIN_OBJC_GO)
    main_java_go = go.actions.declare_file(genpath(ctx, "go", "main.java.go"))
    go.actions.write(main_java_go, MAIN_JAVA_GO)

    run_ex(ctx,
        inputs = srcs,
        outputs = go_files,
        executable = ctx.executable._gobind,
        env = env,
        arguments = [
            # "-lang", "go",
            "-goinstall=false",
            "-outdir", ctx.genfiles_dir.path + "/" + genpath(ctx, "go"),
        ] + packages,
    )

    return struct(
        main_objc_go = depset([main_objc_go]),
        main_java_go = depset([main_java_go]),
        go_files = depset(go_files),
    )
