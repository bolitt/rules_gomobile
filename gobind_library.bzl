load("@co_znly_rules_gomobile//:utils.bzl", "utils")
load("@co_znly_rules_gomobile//:providers.bzl", "GoBindInfo")
load("@io_bazel_rules_go//go:def.bzl", "GoLibrary", "GoPath", "go_binary", "go_context", "go_path")
load("@co_znly_rules_gomobile//:apple.bzl", "apple_untransition_gobind_hdrs", "gobind_to_objc_library")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")

_ANDROID_COPTS = [
    "-D__GOBIND_ANDROID__",
]

_IOS_COPTS = [
    "-D__GOBIND_DARWIN__",
    "-xobjective-c",
    "-fmodules",
    "-fobjc-arc",
]

def _generate_filenames(importpath, java_package, objc_prefix, is_main):
    pkg_short = utils.pkg_short(importpath)
    pkg_short_title = pkg_short.title()
    objc_prefix = objc_prefix.title()
    files = struct(
        importpath = importpath,
        pkg_short = pkg_short,
        go_srcs = [
            "{}.h".format(pkg_short),
            "{}_android.h".format(pkg_short),
            "{}_android.c".format(pkg_short),
            "{}_darwin.h".format(pkg_short),
            "{}{}_darwin.m".format(objc_prefix, pkg_short_title),
        ],
        darwin_hdrs = [
            "{}{}.objc.h".format(objc_prefix, pkg_short_title),
        ],
    )
    if is_main:
        files.go_srcs.append("go_{}main.go".format(pkg_short))
    return files

def _declare_pkg_files(ctx, outputs, pkg, go_main_file, java_package = "", objc_prefix = "", is_main = True):
    files = _generate_filenames(
        importpath = pkg,
        java_package = ctx.attr.java_package,
        objc_prefix = ctx.attr.objc_prefix,
        is_main = is_main,
    )
    outputs.go.extend([
        ctx.actions.declare_file(f, sibling = go_main_file)
        for f in files.go_srcs
    ])
    outputs.objc.extend([
        ctx.actions.declare_file(f, sibling = go_main_file)
        for f in files.darwin_hdrs
    ])

def _declare_seq_files(ctx, outputs, go_main_file):
    outputs.objc.append(ctx.actions.declare_file("ref.h", sibling = go_main_file))
    go_srcs = [
        "seq_android.c",
        "seq_android.go",
        "seq_android.h",
        "seq_darwin.go",
        "seq_darwin.h",
        "seq_darwin.m",
        "seq.go",
        "seq.h",
    ]
    outputs.go.extend([
        ctx.actions.declare_file(src, sibling = go_main_file)
        for src in go_srcs
    ])

def _gobind_library_impl(ctx):
    """_gobind_impl"""
    go = go_context(ctx)
    gopath = ctx.attr.go_path[GoPath]
    packages = [d[GoLibrary].importpath for d in ctx.attr.deps]

    outdir = utils.touch(ctx, paths.join(ctx.label.name, ".marker"))
    go_main = ctx.actions.declare_file(paths.join("src", "gobind", "go_main.go"), sibling = outdir)

    outputs = GoBindInfo(
        go = [go_main],
        java = [],
        objc = [],
    )

    _declare_seq_files(
        ctx,
        outputs = outputs,
        go_main_file = go_main,
    )
    _declare_pkg_files(
        ctx,
        outputs = outputs,
        pkg = "universe",
        go_main_file = go_main,
        is_main = False,
    )
    for pkg in packages:
        _declare_pkg_files(
            ctx,
            outputs = outputs,
            pkg = pkg,
            go_main_file = go_main,
            java_package = ctx.attr.java_package,
            objc_prefix = ctx.attr.objc_prefix,
        )

    srcjar = ctx.actions.declare_file("{}.srcjar".format(ctx.label.name), sibling = outdir)
    outputs.java.append(srcjar)

    utils.run_ex(
        ctx,
        inputs = ctx.files.go_path,
        outputs = outputs.go + outputs.objc + outputs.java,
        mnemonic = "GoBind",
        executable = ctx.executable._gobind_wrapper,
        env = dicts.add(go.env, {
            "CGO_ENABLED": 1,
            "GO111MODULE": "off",
            "GOPATH": paths.join("${PWD}", gopath.gopath_file.dirname),
            "GOROOT": paths.join("${PWD}", go.sdk_root.dirname),
            "PATH": ":".join([
                paths.join("${PWD}", go.sdk_root.dirname, "bin"),
                "${PATH}",
            ]),
        }),
        arguments = [
            "-gobind=" + ctx.executable._gobind.path,
            "-zipper=" + ctx.executable._zipper.path,
            "-outdir=" + outdir.dirname,
            "-outjar=" + srcjar.path,
            "--",
            "-lang=go,objc,java",
            "-javapkg=" + ctx.attr.java_package,
            "-prefix=" + ctx.attr.objc_prefix,
            "-tags=" + ",".join(ctx.attr.go_tags),
            "-outdir=" + outdir.dirname,
        ] + packages,
        tools = [
            go.go,
            ctx.executable._gobind,
            ctx.executable._zipper,
        ],
    )

    library = go.new_library(go, srcs = outputs.go + outputs.objc)
    source = go.library_to_source(go, ctx.attr, library, ctx.coverage_instrumented())

    return [
        outputs,
        library,
        source,
        DefaultInfo(
            files = depset(outputs.go + outputs.objc + outputs.java),
        ),
        OutputGroupInfo(
            go = outputs.go,
            objc = outputs.objc,
            java = outputs.java,
        ),
    ]

_gobind_library = rule(
    _gobind_library_impl,
    attrs = {
        "cgo": attr.bool(default = True),
        "copts": attr.string_list(),
        "go_path": attr.label(
            mandatory = True,
            providers = [GoPath],
        ),
        "go_tags": attr.string_list(),
        "java_package": attr.string(default = ""),
        "objc_prefix": attr.string(default = ""),
        "deps": attr.label_list(
            mandatory = True,
            providers = [GoLibrary],
        ),
        "_go_context_data": attr.label(
            default = "@io_bazel_rules_go//:go_context_data",
        ),
        "_gobind": attr.label(
            executable = True,
            cfg = "exec",
            default = "@co_znly_rules_gomobile//:gobind",
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

def gobind_library(name, deps, java_package = "", objc_prefix = "", apple_platform_type = "", apple_minimum_os_version = "", tags = [], copts = [], visibility = None, **kwargs):
    gopath_name = utils.slug(name, "gopath")
    go_path(
        name = gopath_name,
        mode = "link",
        include_pkg = True,
        include_transitive = False,
        deps = deps + [
            "@org_golang_x_mobile//bind:go_default_library",
            "@org_golang_x_mobile//bind/objc:go_default_library",
            "@org_golang_x_mobile//bind/java:go_default_library",
            "@org_golang_x_mobile//bind/seq:go_default_library",
        ],
        tags = ["manual"],
    )

    gobind_name = utils.slug(name, "gobind")
    _gobind_library(
        name = gobind_name,
        go_path = gopath_name,
        objc_prefix = objc_prefix,
        deps = deps,
        copts = copts + select({
            "@io_bazel_rules_go//go/platform:android": _ANDROID_COPTS,
            "@io_bazel_rules_go//go/platform:ios": _IOS_COPTS,
            "//conditions:default": [],
        }),
        tags = tags + ["manual"],
    )

    java_binary_name = utils.slug(name, "java", "binary")
    go_binary(
        name = java_binary_name,
        embed = [gobind_name],
        deps = deps + [
            "@org_golang_x_mobile//bind/java:go_default_library",
            "@org_golang_x_mobile//bind/seq:go_default_library",
        ],
        out = "libgojni.so",
        copts = copts + _ANDROID_COPTS,
        pure = "off",
        linkmode = "c-shared",
        tags = tags + ["manual"],
        **kwargs
    )

    java_srcs_name = utils.slug(name, "java", "srcs")
    native.filegroup(
        name = java_srcs_name,
        srcs = [gobind_name],
        output_group = "java",
        tags = ["manual"],
    )

    android_library_name = utils.slug(name, "android_library")
    native.android_library(
        name = android_library_name,
        srcs = [java_srcs_name],
        deps = [java_binary_name],
        tags = tags,
        visibility = visibility,
    )

    objc_binary_name = utils.slug(name, "objc", "binary")
    go_binary(
        name = objc_binary_name,
        embed = [gobind_name],
        deps = deps + [
            "@org_golang_x_mobile//bind/java:go_default_library",
            "@org_golang_x_mobile//bind/seq:go_default_library",
        ],
        copts = copts + _IOS_COPTS,
        pure = "off",
        linkmode = "c-archive",
        **kwargs
    )

    objc_library_name = utils.slug(name, "objc")
    gobind_to_objc_library(
        name = objc_library_name,
        gobind_library = gobind_name,
        visibility = visibility,
        deps = [objc_binary_name],
    )

    objc_library_hdrs_name = utils.slug(objc_library_name, "hdrs")
    apple_untransition_gobind_hdrs(
        name = objc_library_hdrs_name,
        minimum_os_version = apple_minimum_os_version,
        platform_type = apple_platform_type,
        dep = gobind_name,
        visibility = visibility,
    )
