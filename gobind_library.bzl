load("@co_znly_rules_gomobile//:common.bzl", "genpath", "pkg_short", "run_ex")
load("@co_znly_rules_gomobile//:providers.bzl", "GoBindInfo")
load("@io_bazel_rules_go//go:def.bzl", "GoLibrary", "GoPath", "go_context", "go_rule")

def _java_classname(pkg):
    return "/".join(pkg.split("."))

def _gen_filenames(importpath, java_package, objc_prefix):
    pkg_short_ = pkg_short(importpath)
    pkg_short_title = pkg_short_.title()
    objc_prefix_ = objc_prefix.title()
    return struct(
        importpath = importpath,
        pkg_short = pkg_short_,
        hdr = pkg_short_ + ".h",
        go_main = "go_" + pkg_short_ + "main.go",
        android_hdr = pkg_short_ + "_android.h",
        android_c = pkg_short_ + "_android.c",
        android_class = "/".join([
            _java_classname(java_package),
            pkg_short_,
            pkg_short_title + ".java",
        ]),
        darwin_hdr = pkg_short_ + "_darwin.h",
        darwin_m = objc_prefix_ + pkg_short_title + "_darwin.m",
        darwin_public_hdr = objc_prefix_ + pkg_short_title + ".objc.h",
    )

def _gen_pkg_files(ctx, go, pkg, java_package, objc_prefix, outputs):
    files = _gen_filenames(pkg, ctx.attr.java_package, ctx.attr.objc_prefix)
    if "go" in ctx.attr.lang:
        outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.hdr)))
        outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.go_main)))
    if "objc" in ctx.attr.lang:
        for filename in [files.darwin_hdr, files.darwin_m]:
            outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))
        outputs.objc.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.darwin_public_hdr)))
    if "java" in ctx.attr.lang:
        for filename in [files.android_hdr, files.android_c]:
            outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))

def _gen_universe_files(ctx, go, outputs):
    files = _gen_filenames("universe", "", "")
    if "go" in ctx.attr.lang:
        outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.hdr)))
    if "objc" in ctx.attr.lang:
        for filename in [files.darwin_hdr, files.darwin_m]:
            outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))
        outputs.objc.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.darwin_public_hdr)))
    if "java" in ctx.attr.lang:
        for filename in [files.android_hdr, files.android_c]:
            outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))

def _gen_seq_files(ctx, go, outputs):
    if "go" in ctx.attr.lang:
        outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq.h")))
        outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq.go")))
    if "objc" in ctx.attr.lang:
        for ext in [".h", ".m"]:
            outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq_darwin" + ext)))
        outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq_darwin.go")))
        outputs.objc.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "ref.h")))
    if "java" in ctx.attr.lang:
        for ext in [".h", ".c"]:
            outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq_android" + ext)))
        outputs.go.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq_android.go")))

def _gobind_library_impl(ctx):
    """_gobind_impl"""
    go = go_context(ctx)

    gopath = ctx.attr.go_path[GoPath]
    packages = [d[GoLibrary].importpath for d in ctx.attr.deps]

    outputs = GoBindInfo(
        go = [],
        java = [],
        objc = [],
    )

    for pkg in packages:
        _gen_pkg_files(ctx, go, pkg, ctx.attr.java_package, ctx.attr.objc_prefix, outputs)

    _gen_universe_files(ctx, go, outputs)
    _gen_seq_files(ctx, go, outputs)

    srcjar_path = ""
    if "java" in ctx.attr.lang:
        srcjar = ctx.actions.declare_file("%s.gobind.srcjar" % ctx.label.name)
        outputs.java.append(srcjar)
        srcjar_path = srcjar.path

    outputs.go.append(
        go.actions.declare_file(genpath(ctx, "src", "gobind", "go_main.go")),
    )

    outdir = "/".join([
        ctx.genfiles_dir.path,
        ctx.label.package,
        ctx.label.name,
    ])

    env = dict(go.env)
    env.update({
        "CGO_ENABLED": 1,
        "GO111MODULE": "off",
        "GOPATH": "${PWD}/" + gopath.gopath_file.dirname,
        "GOROOT": "${PWD}/%s" % go.sdk_root.dirname,
        "PATH": "${PWD}/%s/bin:${PATH}" % go.sdk_root.dirname,
    })

    mnemonic = "GoBind"
    if "objc" in ctx.attr.lang:
        mnemonic += "ObjC"
    if "java" in ctx.attr.lang:
        mnemonic += "Java"
    run_ex(
        ctx,
        inputs = [go.go] + ctx.files.go_path,
        outputs = outputs.go + outputs.objc + outputs.java,
        mnemonic = mnemonic,
        executable = ctx.executable._gobind_wrapper,
        env = env,
        arguments = [
            "-gobind=" + ctx.executable._gobind.path,
            "-zipper=" + ctx.executable._zipper.path,
            "-outdir=" + outdir,
            "-outjar=" + srcjar_path,
            "--",
            "-lang=" + ",".join(ctx.attr.lang),
            "-javapkg=" + ctx.attr.java_package,
            "-prefix=" + ctx.attr.objc_prefix,
            "-tags=" + ",".join(ctx.attr.go_tags),
            "-outdir=" + outdir,
        ] + packages,
        tools = [
            ctx.executable._gobind,
            ctx.executable._zipper,
        ],
    )

    library = go.new_library(go, srcs = outputs.go + outputs.objc)
    return [
        outputs,
        library,
        DefaultInfo(
            files = depset(outputs.go + outputs.objc + outputs.java),
        ),
        OutputGroupInfo(
            go = outputs.go,
            objc = outputs.objc,
            java = outputs.java,
        ),
    ]

gobind_library = go_rule(
    _gobind_library_impl,
    attrs = {
        "cgo": attr.bool(default = True),
        "copts": attr.string_list(),
        "go_path": attr.label(providers = [GoPath]),
        "go_tags": attr.string_list(),
        "java_package": attr.string(default = ""),
        "lang": attr.string_list(mandatory = True),
        "objc_prefix": attr.string(default = ""),
        "deps": attr.label_list(
            providers = [GoLibrary],
        ),
        "_gobind": attr.label(
            executable = True,
            cfg = "exec",
            default = "@org_golang_x_mobile//cmd/gobind:gobind",
        ),
        "_gobind_wrapper": attr.label(
            executable = True,
            cfg = "exec",
            default = "@co_znly_rules_gomobile//:gobind_wrapper",
        ),
        "_zipper": attr.label(
            default = "@bazel_tools//tools/zip:zipper",
            cfg = "exec",
            executable = True,
        ),
    },
    output_to_genfiles = True,
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)
