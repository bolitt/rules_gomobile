load("@co_znly_rules_gomobile//:common.bzl", "genpath", "pkg_short", "run_ex")
load("@co_znly_rules_gomobile//:providers.bzl", "GoBindInfo")
load("@io_bazel_rules_go//go:def.bzl", "GoLibrary", "GoPath", "go_context", "GoSource")

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


def _is_go(ctx):
    return "go" in ctx.attr.lang

def _is_java(ctx):
    return "java" in ctx.attr.lang

def _is_objc(ctx):
    return "objc" in ctx.attr.lang


def _gobind_library_impl(ctx):
    """_gobind_impl"""
    # https://github.com/bazelbuild/rules_go/blob/master/go/toolchains.rst#go_context
    go = go_context(ctx)

    # https://github.com/bazelbuild/rules_go/blob/master/go/providers.rst#gopath
    gopath = ctx.attr.go_path[GoPath]
    packages = [d[GoLibrary].importpath for d in ctx.attr.deps]
    sources = []
    for d in ctx.attr.deps:
        sources += d[GoSource].srcs

    outputs = GoBindInfo(
        go = [],
        java = [],
        objc = [],
    )
    # Old:
    # for pkg in packages:
    #     _gen_pkg_files(ctx, go, pkg, ctx.attr.java_package, ctx.attr.objc_prefix, outputs)
    # _gen_universe_files(ctx, go, outputs)
    # _gen_seq_files(ctx, go, outputs)
    # srcjar_path = ""
    # if "java" in ctx.attr.lang:
    #     srcjar = ctx.actions.declare_file("%s.gobind.srcjar" % ctx.label.name)
    #     outputs.java.append(srcjar)
    #     srcjar_path = srcjar.path
    # outputs.go.append(
    #     go.actions.declare_file(genpath(ctx, "src", "gobind", "go_main.go")),
    # )
    # outdir = "/".join([
    #     ctx.genfiles_dir.path,
    #     ctx.label.package,
    #     ctx.label.name,
    # ])

    # Go envs:
    my_go_root = "${PWD}/%s" % go.root
    my_go_path = "${PWD}/%s" % gopath.gopath_file.dirname
    my_go_cache = "%s/../caches/go-build" % my_go_root
    my_go_tool_dir = "%s/pkg/tool/darwin_amd64" % my_go_root  # compile_path = tool_path + "/compile"

    tools = [
        ctx.executable._gomobile,
        ctx.executable._gobind,
        ctx.executable._zipper,
    ] + ctx.files._go_tools

    # Find bins to execute.
    my_sys_path = ":".join(
        [
            "%s/bin" % my_go_root,
            "%s/bin" % my_go_path,
            my_go_tool_dir,
            "${PATH}",
        ] + ctx.attr.system_path
    )

    out_gobind = None
    lang_specific_env = {
        "JAVA_HOME": "/Users/tianlin/Downloads/dev/java/jdk-16.0.2.jdk/Contents/Home",
    }
    bind_target = ""
    if _is_java(ctx):
        # See usage: gomobile bind --help
        # https://github.com/golang/go/wiki/Mobile
        bind_target = "android"
        jar_file = "%s-sources.jar" % ctx.label.name
        aar_file = "%s.aar" % ctx.label.name
        outputs.java.append(go.actions.declare_file(jar_file))
        outputs.java.append(go.actions.declare_file(aar_file))

        out_gobind = "/".join([
            ctx.genfiles_dir.path,
            ctx.label.package,
            aar_file,
        ])
        
        print('outputs.java: ', outputs.java)
        print('aar_file: ', aar_file)
        print('jar_file: ', jar_file)
        print('out_gobind: ', out_gobind)

        # Android envs:
        sdk_label = Label("@androidsdk")
        ndk_label = Label("@androidndk")
        sdk_home = "${PWD}/%s" % sdk_label.workspace_root  # "${PWD}/external/androidsdk"
        ndk_home = "${PWD}/%s/ndk" % (ndk_label.workspace_root)  # "${PWD}/external/androidsdk/ndk"
        # jdk_label = Label("@bazel_tools")
        # jdk_home = "{PWD}/%s/jdk/bin" % jdk_label.workspace_root  # ${PWD}/external/bazel_tools/jdk
        lang_specific_env.update({
            "ANDROID_HOME": sdk_home,
            "ANDROID_NDK_HOME": ndk_home,
        })
        tools += ctx.files._android_tools

    if _is_objc(ctx):
        bind_target = "ios"
        xcframework_folder = "%s.xcframework" % ctx.label.name
        outputs.objc.append(go.actions.declare_directory(xcframework_folder))

        out_gobind = "/".join([
            ctx.genfiles_dir.path,
            ctx.label.package,
            xcframework_folder,
        ])

    # print('tools: \n', tools)
    # print('ctx.files._go_tools:\n', ctx.files._go_tools)

    # Update env.
    env = dict(go.env)
    env.update({
        "CGO_ENABLED": 1,
        "GO111MODULE": "off",
        "GOROOT": my_go_root,
        "GOPATH": my_go_path,
        "GOCACHE": my_go_cache,
        "PATH": my_sys_path,
        "GOTOOLDIR": my_go_tool_dir,
    })
    env.update(lang_specific_env)

    mnemonic = "GoBind"
    if "objc" in ctx.attr.lang:
        mnemonic += "ObjC"
    if "java" in ctx.attr.lang:
        mnemonic += "Java"

    # arguments = [
    #     "-gomobile=" + ctx.executable._gomobile.path,
    #     "-gobind=" + ctx.executable._gobind.path,
    #     "-zipper=" + ctx.executable._zipper.path,
    #     "-outdir=" + outdir,
    #     "-outjar=" + srcjar_path,
    #     "--",
    #     "-lang=" + ",".join(ctx.attr.lang),
    #     "-javapkg=" + ctx.attr.java_package,
    #     "-prefix=" + ctx.attr.objc_prefix,
    #     "-tags=" + ",".join(ctx.attr.go_tags),
    #     "-outdir=" + outdir,
    # ] + packages

    arguments = [
        "-gomobile=" + ctx.executable._gomobile.path,
        "--",
        "bind",
        "-v",
        "-o", out_gobind,
        "-target=%s" % bind_target,
    ] + packages

    run_ex(
        ctx,
        inputs = [go.go] + ctx.files.go_path,
        outputs = outputs.go + outputs.objc + outputs.java,
        mnemonic = mnemonic,
        gomobile = ctx.executable._gomobile,
        gobind = ctx.executable._gobind,
        executable = ctx.executable._gobind_wrapper,
        env = env,
        arguments = arguments,
        tools = tools,
    )

    library = go.new_library(
        go, 
        srcs = outputs.go + outputs.objc
    )
    return [
        outputs,
        library,
        DefaultInfo(
            files = depset(outputs.go + outputs.objc + outputs.java),
            runfiles = ctx.runfiles(sources)
        ),
        OutputGroupInfo(
            go = outputs.go,
            objc = outputs.objc,
            java = outputs.java,
        ),
    ]

gobind_library = rule(
    implementation = _gobind_library_impl,
    attrs = {
        "cgo": attr.bool(default = True),
        "srcs": attr.label_list(default=[]),
        "copts": attr.string_list(),  # TODO(tianlin): Didn't used.
        "go_path": attr.label(providers = [GoPath]),
        "go_tags": attr.string_list(),  # TODO(tianlin): Didn't used.
        "java_package": attr.string(default = ""),  # TODO(tianlin): Didn't used.
        "lang": attr.string_list(mandatory = True),
        "objc_prefix": attr.string(default = ""),
        "deps": attr.label_list(
            providers = [GoLibrary, GoSource],
        ),
        "system_path": attr.string_list(
            doc = "Additional system path to search binaries",
            default = [
                "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin",
            ],
        ),
        "_android_tools": attr.label_list(
            default = [
                "@androidsdk//:files", "@androidsdk//:sdk", "@androidndk//:files",
            ]
        ),
        "_go_tools": attr.label_list(
            default = [
                "@go_sdk//:files", 
                "@org_golang_x_xerrors//:go_default_library",
            ]
        ),
        "_gomobile": attr.label(
            executable = True,
            cfg = "host",
            default = "@org_golang_x_mobile//cmd/gomobile:gomobile",
        ),
        "_gobind": attr.label(
            executable = True,
            cfg = "host",
            default = "@org_golang_x_mobile//cmd/gobind:gobind",
        ),
        "_gobind_wrapper": attr.label(
            executable = True,
            cfg = "host",
            default = "@co_znly_rules_gomobile//:gobind_wrapper",
        ),
        "_zipper": attr.label(
            default = "@bazel_tools//tools/zip:zipper",
            cfg = "host",
            executable = True,
        ),
    },
    output_to_genfiles = True,
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)
