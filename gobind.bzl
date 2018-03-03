load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_path", "GoLibrary", "GoSource", "GoPath", "go_context")
load("@co_znly_rules_gomobile//:objc.bzl", "gobind_objc")
load("@co_znly_rules_gomobile//:java.bzl", "gobind_java")
load("@co_znly_rules_gomobile//:go.bzl", "gobind_go")
load("@co_znly_rules_gomobile//:common.bzl", "slug", "gen_include_path")
load("@co_znly_rules_gomobile//:constraints.bzl", "PLATFORMS")
load("@co_znly_rules_gomobile//:extract.bzl", "extract")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_static_framework")

def _gobind_impl(ctx):
    """_gobind_impl"""
    go = go_context(ctx)
    gopath = ctx.attr.go_path[GoPath]
    srcs = []
    libraries = []
    for d in ctx.attr.deps:
        library = d[GoLibrary]
        source = d[GoSource]
        srcs.extend(source.srcs)
        libraries.append(library)

    env = {
        "GOPATH": "$(pwd)/" + ctx.bin_dir.path + "/" + gopath.gopath,
    }
    go_out = gobind_go(ctx, go, env, libraries, gopath.srcs)
    objc_out = gobind_objc(ctx, go, env, libraries, gopath.srcs)
    java_out = gobind_java(ctx, go, env, libraries, gopath.srcs)

    return [
        DefaultInfo(
            files = go_out.main_objc_go + go_out.main_java_go + go_out.go_files +
                objc_out.objc_files + objc_out.objc_hdrs + objc_out.go_files +
                java_out.java_files + java_out.cc_files + java_out.go_files,
        ),
        OutputGroupInfo(
            go_main_objc_go = go_out.main_objc_go,
            go_main_java_go = go_out.main_java_go,
            go_files = go_out.go_files,

            objc_hdrs = objc_out.objc_hdrs,
            objc_files = objc_out.objc_files,
            objc_go_files = objc_out.go_files,

            java_files = java_out.java_files,
            java_cc_files = java_out.cc_files,
            java_go_files = java_out.go_files,
        ),
    ]

_gobind = rule(
    _gobind_impl,
    attrs = {
        "deps": attr.label_list(providers = [GoLibrary]),
        "go_path": attr.label(providers = [GoPath]),
        "_go_context_data": attr.label(default = Label("@io_bazel_rules_go//:go_context_data")),
        "_gobind": attr.label(
            executable = True,
            cfg = "host",
            default = Label("@org_golang_x_mobile//cmd/gobind:gobind")),
    },
    output_to_genfiles = True,
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)

def _gobind_java(name, gobind_gen, go_files, deps):
    gomobile_bind_library = slug(name, "java", "gomobile_bind_library")
    gomobile_main_library = slug(name, "java", "gomobile_main_library")
    gomobile_main_binary = "libgojni"
    # gomobile_main_binary = "lib" + name
    main_go = slug(name, "java", "main_go")
    java_files = slug(name, "java", "files")
    java_cc_files = slug(name, "java", "cc_files")
    java_go_files = slug(name, "java", "go_files")
    gomobile_main_binary_java_cc_import = slug(name, "cc_import")
    gomobile_main_binary_java_cc = slug(name, "cc")
    android_library_name = slug(name, "android_library")

    filegroups = {
        "go_main_java_go": main_go,
        "java_files": java_files,
        "java_cc_files": java_cc_files,
        "java_go_files": java_go_files,
    }
    for group, group_name in filegroups.items():
        native.filegroup(
            name = group_name,
            srcs = [gobind_gen],
            output_group = group,
        )

    go_library(
        name = gomobile_bind_library,
        srcs = [
            go_files,
            java_cc_files,
            java_go_files,
        ],
        cgo = True,
        copts = [
            "-iquote", gen_include_path(gobind_gen, "java"),
        ],
        clinkopts = [
            "-landroid",
            "-llog",
        ],
        importpath = "gomobile_bind",
        visibility = ["//visibility:private"],
        deps = deps + [
            "@co_znly_rules_gomobile//gomobile/seq:go_default_library",
        ],
    )
    go_library(
        name = gomobile_main_library,
        srcs = [
            main_go,
        ],
        cgo = True,
        importpath = "gomobile_main",
        visibility = ["//visibility:private"],
        deps = [
            "@co_znly_rules_gomobile//gomobile/bind/java:go_default_library",
            gomobile_bind_library,
        ],
    )
    go_binary(
        name = gomobile_main_binary,
        embed = [gomobile_main_library],
        pure = "off",
        linkmode = "c-shared",
    )
    native.cc_import(
        name = gomobile_main_binary_java_cc_import,
        shared_library = gomobile_main_binary,
    )
    native.cc_library(
        name = gomobile_main_binary_java_cc,
        deps = [gomobile_main_binary_java_cc_import]
    )
    native.android_library(
        name = android_library_name,
        srcs = [java_files],
        deps = [
            gomobile_main_binary_java_cc,
        ],
        visibility = ["//visibility:public"],
    )
    return android_library_name

def _gobind_objc(name, gobind_gen, go_files, deps):
    gomobile_bind_library = slug(name, "objc", "gomobile_bind_library")
    gomobile_main_library = slug(name, "objc", "gomobile_main_library")
    gomobile_main_binary = slug(name, "objc", "gomobile_main_binary")
    main_go = slug(name, "objc", "main_go")
    objc_hdrs = slug(name, "objc", "hdrs")
    objc_files = slug(name, "objc", "files")
    objc_go_files = slug(name, "objc", "go_files")

    filegroups = {
        "go_main_objc_go": main_go,
        "objc_hdrs": objc_hdrs,
        "objc_files": objc_files,
        "objc_go_files": objc_go_files,
    }
    for group, group_name in filegroups.items():
        native.filegroup(
            name = group_name,
            srcs = [gobind_gen],
            output_group = group,
        )
    go_library(
        name = gomobile_bind_library,
        srcs = [go_files, objc_files, objc_hdrs],
        cgo = True,
        copts = [
            "-iquote", gen_include_path(gobind_gen, "objc"),
            "-x", "objective-c",
            "-fmodules",
            "-fobjc-arc",
            "-Wno-shorten-64-to-32",
        ],
        objcopts = {
            "enable_modules": 1,
        },
        importpath = "gomobile_bind",
        visibility = ["//visibility:private"],
        deps = deps + [
            "@co_znly_rules_gomobile//gomobile/seq:go_default_library",
        ],
    )
    go_library(
        name = gomobile_main_library,
        srcs = [
            main_go,
        ],
        cgo = True,
        importpath = "gomobile_main",
        visibility = ["//visibility:private"],
        deps = [
            gomobile_bind_library,
        ],
    )
    go_binary(
        name = gomobile_main_binary,
        embed = [gomobile_main_library],
        pure = "off",
        linkmode = "c-archive",
    )
    # objc deps can only have underscores and dashes
    native.objc_import(
        name = slug(name, "objc", token="_"),
        hdrs = [objc_hdrs],
        alwayslink = 1,
        archives = [gomobile_main_binary],
        visibility = ["//visibility:public"],
    )
    return gomobile_main_binary

def gobind(name, deps, build_dir):
    gopath_gen = slug(name, "go_path")
    go_path(
        name = gopath_gen,
        tags = ["manual"],
        deps = deps + [
            "@co_znly_rules_gomobile//gomobile/bind:go_default_library",
            "@co_znly_rules_gomobile//gomobile/bind/objc:support_library",
            "@co_znly_rules_gomobile//gomobile/bind/java:support_library",
            "@co_znly_rules_gomobile//gomobile/seq:go_default_library",
        ],
    )

    gobind_gen = slug(name, "gobind")
    _gobind(
        name = gobind_gen,
        deps = deps,
        go_path = gopath_gen,
    )

    go_files = slug(name, "go_files")

    filegroups = {
        "go_files": go_files,
    }
    for group, group_name in filegroups.items():
        native.filegroup(
            name = group_name,
            srcs = [gobind_gen],
            output_group = group,
        )

    _gobind_java(name, gobind_gen, go_files, deps)
    _gobind_objc(name, gobind_gen, go_files, deps)

    # gomobile_bind_library_objc = slug(gomobile_bind_library, "objc")
    # go_library(
    #     name = gomobile_bind_library_objc,
    #     srcs = [go_files, objc_files, objc_hdrs],
    #     cgo = True,
    #     copts = [
    #         "-iquote", gen_include_path(gobind_gen, "objc"),
    #         "-x", "objective-c",
    #         "-fmodules",
    #         "-fobjc-arc",
    #         "-Wno-shorten-64-to-32",
    #     ],
    #     objcopts = {
    #         "enable_modules": 1,
    #     },
    #     importpath = "gomobile_bind",
    #     visibility = ["//visibility:private"],
    #     deps = deps + [
    #         "@co_znly_rules_gomobile//gomobile/seq:go_default_library",
    #     ],
    # )

    # gomobile_bind_library_java = slug(gomobile_bind_library, "java")
    # go_library(
    #     name = gomobile_bind_library_java,
    #     srcs = [go_files, java_cc_files, java_go_files],
    #     cgo = True,
    #     copts = [
    #         "-iquote", gen_include_path(gobind_gen, "java"),
    #     ],
    #     clinkopts = [
    #         "-llog",
    #     ],
    #     importpath = "gomobile_bind",
    #     visibility = ["//visibility:private"],
    #     deps = deps + [
    #         "@co_znly_rules_gomobile//gomobile/seq:go_default_library",
    #     ],
    # )

    # go_library(
    #     name = gomobile_main_library,
    #     srcs = [go_main_go],
    #     cgo = True,
    #     importpath = "gomobile_main",
    #     visibility = ["//visibility:private"],
    #     deps = select({
    #         "@co_znly_rules_gomobile//platform:ios": [gomobile_bind_library_objc],
    #         "@co_znly_rules_gomobile//platform:android": [
    #             gomobile_bind_library_java,
    #             "@co_znly_rules_gomobile//gomobile/bind/java:go_default_library",
    #         ],
    #     }),
    # )
    # gomobile_main_binary_objc = slug(gomobile_main_binary, "objc")
    # go_binary(
    #     name = gomobile_main_binary_objc,
    #     embed = [gomobile_main_library],
    #     pure = "off",
    #     linkmode = "c-archive",
    # )
    # gomobile_main_binary_java = slug(gomobile_main_binary, "java")
    # go_binary(
    #     name = "libgojni",
    #     embed = [gomobile_main_library],
    #     pure = "off",
    #     linkmode = "c-shared",
    # )
    # native.filegroup(
    #     name = slug(name, "gomobile"),
    #     srcs = select({
    #         "@co_znly_rules_gomobile//platform:ios": [
    #             gomobile_main_binary_objc,
    #             objc_hdrs,
    #         ],
    #         "@co_znly_rules_gomobile//platform:android": [
    #             ":libgojni",
    #             java_files,
    #         ],
    #     }),
    # )

    # gomobile_main_binary_java_cc_import = slug(name, "cc_import")
    # gomobile_main_binary_java_cc = slug(name, "cc")
    # native.cc_import(
    #     name = gomobile_main_binary_java_cc_import,
    #     shared_library = ":libgojni",
    # )
    # native.cc_library(
    #     name = gomobile_main_binary_java_cc,
    #     deps = [gomobile_main_binary_java_cc_import]
    # )
    # native.android_library(
    #     name = slug(name, "android_library"),
    #     srcs = [java_files],
    #     deps = [
    #         gomobile_main_binary_java_cc,
    #     ],
    #     visibility = ["//visibility:public"],
    # )

    # Finally we extract the built artefacts from the sandbox, to be later
    # reused in another bazel build but without the dependency chain.
    # extract(
    #     name = slug(name, "extract"),
    #     original_name = name,
    #     objc_hdrs = objc_hdrs,
    #     java = java_files,
    #     gomobile_main_binary = select({
    #         "@co_znly_rules_gomobile//platform:ios": gomobile_main_binary_objc,
    #         "@co_znly_rules_gomobile//platform:android": gomobile_main_binary_java,
    #     }),
    #     tags = ["no-sandbox", "no-cache"],
    # )

    # The bazel dependency chain breaks here. It must be carried on externally
    # via another bazel run. The select on ios_cpu makes sure the right archive
    # will get selected by the mutli arch rules later on, starting with the
    # ios_static_framework.
    # archives = {}
    # for cpu in PLATFORMS:
    #     archives["@build_bazel_rules_apple//apple:" + cpu] = [
    #         "build/{0}/{0}.{1}.a".format(name, cpu),
    #     ]
    # native.filegroup(
    #     name = slug(name, "public_hdrs"),
    #     srcs = native.glob(["build/%s/hdrs/*.h" % name]),
    # )
    # native.objc_import(
    #     name = gomobile_objc_import,
    #     archives = select(archives),
    #     alwayslink = 1,
    #     visibility = ["//visibility:public"],
    # )
