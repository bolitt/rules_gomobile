load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "GoLibrary", "GoSource", "go_context")
load("@co_znly_rules_gomobile//:objc.bzl", "gobind_objc")
load("@co_znly_rules_gomobile//:java.bzl", "gobind_java")
load("@co_znly_rules_gomobile//:go.bzl", "gobind_go")
load("@co_znly_rules_gomobile//:common.bzl", "slug", "gen_include_path")
load("@co_znly_rules_gomobile//:constraints.bzl", "PLATFORMS")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_static_framework")

def _gobind_impl(ctx):
    """_gobind_impl"""
    go = go_context(ctx)
    srcs = []
    libraries = []
    for d in ctx.attr.deps:
        library = d[GoLibrary]
        source = d[GoSource]
        srcs.extend(source.srcs)
        libraries.append(library)

    go_out = gobind_go(ctx, go, libraries, srcs)
    objc_out = gobind_objc(ctx, go, libraries, srcs)
    java_out = gobind_java(ctx, go, libraries, srcs)

    return [
        DefaultInfo(
            files = go_out.main_go + go_out.go_files +
                objc_out.objc_files + objc_out.objc_hdrs + objc_out.go_files +
                java_out.java_files + java_out.cc_files + java_out.go_files,
        ),
        OutputGroupInfo(
            go_main_go = go_out.main_go,
            go_files = go_out.go_files,

            objc_hdrs = objc_out.objc_hdrs,
            objc_files = objc_out.objc_files,
            objc_go_files = objc_out.go_files,

            java_files = java_out.java_files,
            java_cc_files = java_out.cc_files,
            java_go_files = java_out.go_files,
        ),
    ]


    #     names = _gobind_ios_names(library)
    #     objc_names.append(names)
    #     bound_pkgs.append(names)
    #     packages.append(library.importpath)

    #     for filename in [names.objc_h, names.objc_m, names.main_h] + GOBIND_SUPPORT_IOS_OBJC_FILES:
    #         outs_objc.append(go.actions.declare_file(_genpath(ctx, "objc", filename)))

    #     for filename in [names.main_go] + GOBIND_SUPPORT_IOS_GO_FILES:
    #         outs_go.append(go.actions.declare_file(_genpath(ctx, "go", filename)))

    #     java_names = _gobind_java_names(library)
    #     for filename in [java_names.pkg_class_java, java_names.pkg_java_h, java_names.pkg_java_c] + GOBIND_SUPPORT_JAVA_FILES:
    #         outs_java.append(go.actions.declare_file(_genpath(ctx, "java", filename)))
    # go_main = go.actions.declare_file(_genpath(ctx, "go", "main.go"))
    # go.actions.write(go_main, _gen_go_main(bound_pkgs))

    # ref_h = [f for f in outs_objc if f.basename == "ref.h"]
    # ctx.actions.run(
    #     inputs = srcs,
    #     outputs = outs_objc,
    #     executable = ctx.executable._gobind,
    #     env = env,
    #     arguments = [
    #         "-lang", "objc",
    #         "-outdir", "{}/{}".format(ctx.genfiles_dir.path, _genpath(ctx, "objc")),
    #     ] + packages,
    # )
    # ctx.actions.run(
    #     inputs = srcs,
    #     outputs = outs_go,
    #     executable = ctx.executable._gobind,
    #     env = env,
    #     arguments = [
    #         "-lang", "go",
    #         "-outdir", "{}/{}".format(ctx.genfiles_dir.path, _genpath(ctx, "go")),
    #     ] + packages,
    # )
    # ctx.actions.run(
    #     inputs = srcs,
    #     outputs = outs_java,
    #     executable = ctx.executable._gobind,
    #     env = env,
    #     arguments = [
    #         "-lang", "java",
    #         "-outdir", "{}/{}".format(ctx.genfiles_dir.path, _genpath(ctx, "java")),
    #     ] + packages,
    # )
    # return [
    #     DefaultInfo(
    #         files = depset(outs_objc + outs_go + [go_main]),
    #     ),
    #     OutputGroupInfo(
    #         go_files = depset(outs_go),
    #         # objc_files = depset(outs_objc),
    #         # objc_hdrs = depset([objc_hdr]),
    #         # objc_hdrs = depset(ref_h + [f for f in outs_objc if f.basename.endswith(".objc.h")]),
    #         # java_files = outs_java,
    #         go_main = depset([go_main]),
    #     ),
    # ]

_gobind = rule(
    _gobind_impl,
    attrs = {
        "deps": attr.label_list(providers = [GoLibrary]),
        "_go_context_data": attr.label(default = Label("@io_bazel_rules_go//:go_context_data")),
        "_gobind": attr.label(
            executable = True,
            cfg = "host",
            default = Label("@org_golang_x_mobile//cmd/gobind:gobind")),
    },
    output_to_genfiles = True,
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)

def gobind(name, deps, framework=None):
    gobind_gen = slug(name, "gobind")
    _gobind(
        name = gobind_gen,
        deps = deps,
    )

    go_files = slug(name, "go_files")
    go_main_go = slug(name, "go_main_go")
    objc_hdrs = slug(name, "objc_hdrs")
    objc_files = slug(name, "objc_files")
    objc_go_files = slug(name, "objc_go_files")

    gomobile_bind_library = slug(name, "gomobile_bind_library")
    gomobile_main_library = slug(name, "gomobile_main_library")
    gomobile_main_binary = slug(name, "gomobile_main_binary")
    gomobile_main_framework = slug(name, "gomobile_main_binary")
    # objc deps can only have underscores and dashes
    gomobile_objc_library = slug(name, "objc", token="_")

    filegroups = {
        "go_main_go": go_main_go,
        "go_files": go_files,

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
        srcs = [go_files] + select({
            "@io_bazel_rules_go//go/platform:darwin": [objc_files, objc_hdrs],
            # "@io_bazel_rules_go//go/platform:android": [java_files],
            "//conditions:default": [],
        }),
        cgo = True,
        objc = {
            "enable_modules": 1,
        },
        clinkopts = select({
            "@io_bazel_rules_go//go/platform:darwin": [
                "-framework Foundation",
            ],
            "//conditions:default": [],
        }),
        copts = select({
            "@io_bazel_rules_go//go/platform:darwin": [
                "-iquote", gen_include_path(gobind_gen, "objc"),
                "-x", "objective-c",
                "-fmodules",
                "-fobjc-arc",
                "-Wno-shorten-64-to-32",
            ],
            "//conditions:default": [],
        }),
        importpath = "gomobile_bind",
        visibility = ["//visibility:private"],
        deps = deps + [
            "@co_znly_rules_gomobile//gomobile/seq:go_default_library",
        ],
    )
    go_library(
        name = gomobile_main_library,
        srcs = [go_main_go],
        cgo = True,
        importpath = "gomobile_main",
        visibility = ["//visibility:private"],
        copts = select({
            "@io_bazel_rules_go//go/platform:darwin": [
                "-iquote", gen_include_path(gobind_gen, "objc"),
                "-x", "objective-c",
                "-fmodules",
                "-fobjc-arc",
                "-Wno-shorten-64-to-32",
            ],
            "//conditions:default": [],
        }),
        clinkopts = select({
            "@io_bazel_rules_go//go/platform:darwin": [
                "-framework Foundation",
            ],
            "//conditions:default": [],
        }),
        deps = [gomobile_bind_library],
    )
    deps = {
        "//conditions:default": [],
    }
    for cpu, (goos, goarch) in PLATFORMS.items():
        go_binary(
            name = "{}_{}_{}".format(gomobile_main_binary, goos, goarch),
            embed = [gomobile_main_library],
            linkmode = "c-archive",
            goos = goos,
            goarch = goarch,
        )
        deps["@co_znly_rules_gomobile//:" + cpu] = [":{}_{}_{}.objc".format(gomobile_main_binary, goos, goarch)]
    native.objc_library(
        name = gomobile_objc_library,
        hdrs = [objc_hdrs],
        deps = select(deps),
        enable_modules = 1,
        alwayslink = 1,
        visibility = ["//visibility:public"],
    )
    if framework:
        ios_static_framework(
            name = name + ".framework",
            hdrs = [objc_hdrs],
            deps = [gomobile_objc_library],
            bundle_name = name,
            visibility = ["//visibility:public"],
            **framework
        )
