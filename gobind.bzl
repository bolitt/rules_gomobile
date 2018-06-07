load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_path", "GoLibrary", "GoSource", "GoPath", "go_context")
load("@co_znly_rules_gomobile//:common.bzl", "slug", "gen_include_path")
load("@co_znly_rules_gomobile//:common.bzl", "pkg_short", "genpath", "run_ex")

_SUPPORT_FILES_JAVA = [
    "go/error.java",
    "go/LoadJNI.java",
]

_GGO_ARGS_PREFIXED = [
    "-I",
    "-L",
    "--include=",
    "--sysroot=",
]

_CGO_ARGS_NEXT = {
    "-I":             None,
    "-L":             None,
    "-isysroot":      None,
    "-isystem":       None,
    "-iquote":        None,
    "-include":       None,
    "--sysroot":      None,
    "-gcc-toolchain": None,
}

def _pwd_arg(args):
    ret = args[:]
    for i, arg in enumerate(args):
        if arg in _CGO_ARGS_NEXT:
            ret[i + 1] = "${PWD}/" + args[i + 1]
            continue
        for prefix in _GGO_ARGS_PREFIXED:
            if arg.startswith(prefix):
                ret[i] = prefix + "${PWD}/" + arg[len(prefix):]
                break
    return ret

def _gen_filenames(importpath):
    pkg_short_ = pkg_short(importpath)
    pkg_short_title = pkg_short_.title()
    return struct(
        importpath = importpath,
        pkg_short = pkg_short_,

        hdr = pkg_short_ + ".h",

        go_main = "go_" + pkg_short_ + "main.go",

        android_hdr = pkg_short_ + "_android.h",
        android_c = pkg_short_ + "_android.c",
        android_class = pkg_short_ + "/" + pkg_short_title + ".java",

        darwin_hdr = pkg_short_ + "_darwin.h",
        darwin_m = pkg_short_title + "_darwin.m",
        darwin_public_hdr = pkg_short_title + ".objc.h",
    )

def _gen_pkg_files(ctx, go, pkg, outputs):
        files = _gen_filenames(pkg)
        outputs.cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.hdr)))
        for filename in [files.darwin_hdr, files.darwin_m]:
            outputs.darwin_cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))
        outputs.darwin_public_hdrs.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.darwin_public_hdr)))
        for filename in [files.android_hdr, files.android_c]:
            outputs.android_cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))
        outputs.android_java_files.append(go.actions.declare_file(genpath(ctx, "java",  "/".join(ctx.attr.android_java_package.split(".")), files.android_class)))
        outputs.go_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.go_main)))

def _gen_universe_files(ctx, go, outputs):
    files = _gen_filenames("universe")
    outputs.cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.hdr)))
    for filename in [files.darwin_hdr, files.darwin_m]:
        outputs.darwin_cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))
    outputs.darwin_public_hdrs.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.darwin_public_hdr)))
    for filename in [files.android_hdr, files.android_c]:
        outputs.android_cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))
    outputs.android_java_files.append(go.actions.declare_file(genpath(ctx, "java", "go", "Universe.java")))

def _gen_seq_files(ctx, go, outputs):
    outputs.cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq.h")))
    for ext in [".h", ".m"]:
        outputs.darwin_cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq_darwin" + ext)))
    outputs.darwin_go_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq_darwin.go")))
    for ext in [".h", ".c"]:
        outputs.android_cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq_android" + ext)))
    outputs.android_go_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq_android.go")))
    outputs.go_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq.go")))
    outputs.android_java_files.append(go.actions.declare_file(genpath(ctx, "java", "go", "Seq.java")))

def _gen_support_files(ctx, go, outputs):
    for file in _SUPPORT_FILES_JAVA:
        outputs.android_java_files.append(go.actions.declare_file(genpath(ctx, "java", file)))
    outputs.darwin_public_hdrs.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "ref.h")))

def _gen_exported_types(ctx, go, outputs):
    for dep, types_str in ctx.attr.deps.items():
        lib = dep[GoLibrary]
        pkg_short_ = pkg_short(lib.importpath)
        for type_ in types_str.split(","):
            outputs.android_java_files.append(go.actions.declare_file(genpath(ctx, "java", "/".join(ctx.attr.android_java_package.split(".")), pkg_short_, type_ + ".java")))

def _gobind_impl(ctx):
    """_gobind_impl"""
    go = go_context(ctx)
    gopath = ctx.attr.go_path[GoPath]

    packages = [d[GoLibrary].importpath for d in ctx.attr.deps]

    outputs = struct(
        go_main = [],
        go_files = [],
        cc_files = [],
        android_go_files = [],
        android_cc_files = [],
        android_java_files = [],
        darwin_go_files = [],
        darwin_cc_files = [],
        darwin_public_hdrs = [],
    )

    for pkg in packages:
        _gen_pkg_files(ctx, go, pkg, outputs)

    _gen_universe_files(ctx, go, outputs)
    _gen_seq_files(ctx, go, outputs)
    _gen_support_files(ctx, go, outputs)
    _gen_exported_types(ctx, go, outputs)

    outputs.go_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "go_main.go")))

    env = {
        "GOROOT": "${PWD}/" + go.root,
        "GOROOT_FINAL": "GOROOT",
        "PATH": "${PWD}/" + go.root + "/bin:${PATH}",
        "GOPATH": "${PWD}/" + gopath.gopath_file.dirname,
        "GOOS": go.mode.goos,
        "GOARCH": go.mode.goarch,
        "CGO_ENABLED": 1,
    }
    outs = outputs.go_files + \
        outputs.cc_files + \
        outputs.android_go_files + \
        outputs.android_cc_files + \
        outputs.android_java_files + \
        outputs.darwin_go_files + \
        outputs.darwin_cc_files + \
        outputs.darwin_public_hdrs

    run_ex(ctx,
        inputs = go.sdk_files + go.sdk_tools + go.crosstool + ctx.files.go_path,
        outputs = outs,
        mnemonic = "GoBind",
        executable = ctx.executable._gobind,
        env = env,
        arguments = [
            "-outdir", ctx.genfiles_dir.path + "/" + genpath(ctx),
            "-javapkg", ctx.attr.android_java_package,
            #"-goinstall=false",
        ] + packages,
    )

    return [
        outputs,
        DefaultInfo(
            files = depset(outs),
        ),
        OutputGroupInfo(
            go_files = outputs.go_files,
            cc_files = outputs.cc_files,
            android_go_files = outputs.android_go_files,
            android_cc_files = outputs.android_cc_files,
            android_java_files = outputs.android_java_files,
            darwin_go_files = outputs.darwin_go_files,
            darwin_cc_files = outputs.darwin_cc_files,
            darwin_public_hdrs = outputs.darwin_public_hdrs,
        ),
    ]

_gobind = rule(
    _gobind_impl,
    attrs = {
        "deps": attr.label_keyed_string_dict(providers = [GoLibrary]),
        "go_path": attr.label(providers = [GoPath]),
        "android_java_package": attr.string(mandatory=True),
        "_go_context_data": attr.label(default = Label("@io_bazel_rules_go//:go_context_data")),
        "_gobind": attr.label(
            executable = True,
            cfg = "host",
            default = Label("@org_golang_x_mobile//cmd/gobind:gobind")),
    },
    output_to_genfiles = True,
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)

def _gobind_java(name, groups, gobind_gen, deps):
    gomobile_main_library = slug(name, "java", "gomobile_main_library")
    # gomobile_main_binary = slug(name, "java", "gomobile_main_binary")
    gomobile_main_binary = "gojni"
    gomobile_main_binary_cc_import = slug(name, "java", "cc_import")
    gomobile_main_binary_cc_library = slug(name, "java", "cc_library")
    android_library_name = slug(name, "android_library")
    go_library(
        name = gomobile_main_library,
        srcs = [
            groups["go_files"],
            groups["cc_files"],
            groups["android_cc_files"],
            groups["android_go_files"],
        ],
        cgo = True,
        copts = [
            "-D__GOBIND_ANDROID__",
            "-iquote", "$(GENDIR)/%s/src/gobind" % gobind_gen,
        ],
        clinkopts = [
            "-landroid",
            "-llog",
            "-ldl",
        ],
        importpath = "main",
        visibility = ["//visibility:private"],
        deps = deps.keys() + [
            "@org_golang_x_mobile//bind/java:go_default_library",
            "@org_golang_x_mobile//bind/seq:go_default_library",
        ],
    )
    go_binary(
        name = gomobile_main_binary,
        embed = [gomobile_main_library],
        pure = "off",
        linkmode = "c-shared",
        visibility = ["//visibility:public"],
    )
    native.cc_import(
        name = gomobile_main_binary_cc_import,
        shared_library = gomobile_main_binary,
    )
    native.cc_library(
        name = gomobile_main_binary_cc_library,
        deps = [gomobile_main_binary_cc_import],
        linkstatic = 1,
        alwayslink = 1,
    )
    native.android_library(
        name = android_library_name,
        srcs = [
            groups["android_java_files"],
        ],
        deps = [
            gomobile_main_binary_cc_library,
        ],
        visibility = ["//visibility:public"],
    )
    return android_library_name

# def _gobind_objc(name, gobind_gen, go_files, deps):
#     gomobile_bind_library = slug(name, "objc", "gomobile_bind_library")
#     gomobile_main_library = slug(name, "objc", "gomobile_main_library")
#     gomobile_main_binary = slug(name, "objc", "gomobile_main_binary")
#     main_go = slug(name, "objc", "main_go")
#     objc_hdrs = slug(name, "objc", "hdrs")
#     objc_files = slug(name, "objc", "files")
#     objc_go_files = slug(name, "objc", "go_files")

#     filegroups = {
#         "go_main_objc_go": main_go,
#         "objc_hdrs": objc_hdrs,
#         "objc_files": objc_files,
#         "objc_go_files": objc_go_files,
#     }
#     for group, group_name in filegroups.items():
#         native.filegroup(
#             name = group_name,
#             srcs = [gobind_gen],
#             output_group = group,
#         )
#     go_library(
#         name = gomobile_bind_library,
#         srcs = [go_files, objc_files, objc_hdrs],
#         cgo = True,
#         copts = [
#             "-iquote", gen_include_path(gobind_gen, "objc"),
#             "-x", "objective-c",
#             "-fmodules",
#             "-fobjc-arc",
#             "-Wno-shorten-64-to-32",
#         ],
#         objcopts = {
#             "enable_modules": 1,
#         },
#         importpath = "gomobile_bind",
#         visibility = ["//visibility:private"],
#         deps = deps + [
#             "@co_znly_rules_gomobile//gomobile/seq:go_default_library",
#         ],
#     )
#     go_library(
#         name = gomobile_main_library,
#         srcs = [
#             main_go,
#         ],
#         cgo = True,
#         importpath = "gomobile_main",
#         visibility = ["//visibility:private"],
#         deps = [
#             gomobile_bind_library,
#         ],
#     )
#     go_binary(
#         name = gomobile_main_binary,
#         embed = [gomobile_main_library],
#         pure = "off",
#         linkmode = "c-archive",
#     )
#     # objc deps can only have underscores and dashes
#     native.objc_import(
#         name = slug(name, "objc", token="_"),
#         hdrs = [objc_hdrs],
#         alwayslink = 1,
#         archives = [gomobile_main_binary],
#         visibility = ["//visibility:public"],
#     )
#     return gomobile_main_binary

def gobind(name, deps, android_java_package):
    gopath_gen = slug(name, "gopath")
    go_path(
        name = gopath_gen,
        mode = "link",
        deps = deps.keys() + [
            "@org_golang_x_mobile//bind:go_default_library",
            "@org_golang_x_mobile//bind/objc:go_default_library",
            "@org_golang_x_mobile//bind/java:go_default_library",
            "@org_golang_x_mobile//bind/seq:go_default_library",
        ],
    )

    _deps = {}
    for dep, exported_types in deps.items():
        _deps[dep] = ",".join(exported_types)

    gobind_gen = slug(name, "gobind")
    _gobind(
        name = gobind_gen,
        go_path = gopath_gen,
        android_java_package = android_java_package,
        deps = _deps,
    )

    go_files = slug(name, "go_files")
    go_main = slug(name, "go_main")
    go_files = slug(name, "go_files")
    cc_files = slug(name, "cc_files")
    android_go_files = slug(name, "android_go_files")
    android_cc_files = slug(name, "android_cc_files")
    android_java_files = slug(name, "android_java_files")
    darwin_go_files = slug(name, "darwin_go_files")
    darwin_cc_files = slug(name, "darwin_cc_files")
    darwin_public_hdrs = slug(name, "darwin_public_hdrs")

    _group_names = [
        "go_main",
        "go_files",
        "cc_files",
        "android_go_files",
        "android_cc_files",
        "android_java_files",
        "darwin_go_files",
        "darwin_cc_files",
        "darwin_public_hdrs",
    ]
    groups = {}

    # filegroups = {
    #     "go_files": go_files,
    #     "go_main": go_main,
    #     "go_files": go_files,
    #     "cc_files": cc_files,
    #     "android_go_files": android_go_files,
    #     "android_cc_files": android_cc_files,
    #     "android_java_files": android_java_files,
    #     "darwin_go_files": darwin_go_files,
    #     "darwin_cc_files": darwin_cc_files,
    #     "darwin_public_hdrs": darwin_public_hdrs,
    # }
    for group_name in _group_names:
        target_group_name = slug(name, group_name)
        groups[group_name] = target_group_name
        native.filegroup(
            name = target_group_name,
            srcs = [gobind_gen],
            output_group = group_name,
        )

    _gobind_java(name, groups, gobind_gen, _deps)
#     # _gobind_objc(name, gobind_gen, go_files, deps)
