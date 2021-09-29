load("//tools/rule_mobile:common.bzl", "run_executable")
load("//tools/rule_mobile:providers.bzl", "GoBindInfo")
load("@io_bazel_rules_go//go:def.bzl", "GoLibrary", "GoPath", "go_context", "GoSource")

# Linux/Unix bins.
# It provides basic cmds, such as `ls`, `pwd`, `dirname`, etc.
LINUX_UNIX_BINS = ["/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]


def gen_files(label_name, original_name):
    """Generated files of gobind_library."""
    return struct(
        short_android_aar = original_name + ".aar",
        android_aar = "/".join([
            label_name,
            original_name + ".aar"
        ]),
        short_android_sources_jar = original_name + "-sources.jar",
        android_sources_jar = "/".join([
            label_name,
            original_name + "-sources.jar",
        ]),
        short_xcframework = original_name + ".xcframework",
        xcframework = "/".join([
            label_name,
            original_name + ".xcframework",
        ])
    )


def _is_java(ctx):
    return "java" == ctx.attr.lang


def _is_objc(ctx):
    return "objc" == ctx.attr.lang


def _gobind_library_impl(ctx):
    """_gobind_impl"""
    # ctx: https://docs.bazel.build/versions/main/skylark/lib/ctx.html

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
    

    # Go envs:
    my_go_root = "${PWD}/%s" % go.root
    my_go_path = "${PWD}/%s" % gopath.gopath_file.dirname
    my_go_cache = "%s/../caches/go-build" % my_go_root
    my_go_tool_dir = "%s/pkg/tool/darwin_amd64" % my_go_root  # compile_path = tool_path + "/compile"

    tools = [ctx.executable._gomobile] + ctx.files._go_tools + ctx.files._jdk
    java_runtime = ctx.attr._jdk[java_common.JavaRuntimeInfo]
    jdk_path = java_runtime.java_home

    # Find bins to execute.
    my_sys_path = ":".join(
        [
            "%s/bin" % my_go_root,
            "%s/bin" % my_go_path,
            my_go_tool_dir,
            "${PATH}",
        ] + ctx.attr.system_path
    )

    gen = gen_files(ctx.label.name, ctx.attr.original_name)
    out_gobind = None
    lang_specific_env = {}
    bind_target = ""
    if _is_java(ctx):
        # See usage: gomobile bind --help
        # https://github.com/golang/go/wiki/Mobile
        bind_target = "android"

        outputs.java.append(go.actions.declare_file(gen.android_aar))
        outputs.java.append(go.actions.declare_file(gen.android_sources_jar))

        # Real out_gobind path.
        out_gobind = "/".join([
            ctx.genfiles_dir.path,
            ctx.label.package,
            gen.android_aar,
        ])

        # Android envs:
        sdk_label = Label("@androidsdk")
        ndk_label = Label("@androidndk")
        sdk_home = "${PWD}/%s" % sdk_label.workspace_root  # "${PWD}/external/androidsdk"
        ndk_home = "${PWD}/%s/ndk" % (ndk_label.workspace_root)  # "${PWD}/external/androidsdk/ndk"

        lang_specific_env.update({
            "ANDROID_HOME": sdk_home,
            "ANDROID_NDK_HOME": ndk_home,
        })
        tools += ctx.files._android_tools

    elif _is_objc(ctx):
        bind_target = "ios"
        outputs.objc.append(go.actions.declare_directory(gen.xcframework))

        # Real out_gobind path (xcframework folder).
        out_gobind = "/".join([
            ctx.genfiles_dir.path,
            ctx.label.package,
            gen.xcframework,
        ])  


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

    arguments = [
        # Parse flags for gobind_wrapper.
        "-gomobile=" + ctx.executable._gomobile.path,
        "--check_target=%s" % bind_target,
        "--",
        # Below are unparsed flags (as subprocess args).
        "bind",
        "-v",
        "-o", out_gobind,
        "-target=%s" % bind_target,
    ] + ctx.attr.gen_args + packages

    mnemonic = "GoBind"
    if _is_objc(ctx):
        mnemonic += "ObjC"
    elif _is_java(ctx):
        mnemonic += "Java"
    
    # Run executable to generate target bindings.
    run_executable(
        ctx,
        inputs = [go.go] + ctx.files.go_path + ctx.files._jdk,
        outputs = outputs.go + outputs.objc + outputs.java,
        mnemonic = mnemonic,
        gomobile = ctx.executable._gomobile,
        executable = ctx.executable._gobind_wrapper,
        jdk_path = jdk_path,
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
        "go_path": attr.label(providers = [GoPath]),
        "original_name": attr.string(
            mandatory = True,
            doc = "Original label name",
        ),
        "lang": attr.string(
            mandatory = True,
            values = ["java", "objc"],
            doc = "Target language to generate.",
        ),
        "gen_args": attr.string_list(
            default = [],
            doc = "Code generate flags for `gomobile bind`",
        ),
        "deps": attr.label_list(
            providers = [GoLibrary, GoSource],
        ),
        "system_path": attr.string_list(
            doc = "Additional system path to search binaries",
            default = LINUX_UNIX_BINS,
        ),
        "_jdk": attr.label(
            default = Label("@bazel_tools//tools/jdk:current_java_runtime"),
            cfg = "host",
            providers = [java_common.JavaRuntimeInfo],
        ),
        "_gomobile": attr.label(
            executable = True,
            cfg = "host",
            default = "@org_golang_x_mobile//cmd/gomobile:gomobile",
        ),
        "_gobind_wrapper": attr.label(
            executable = True,
            cfg = "host",
            default = "//tools/rule_mobile:gobind_wrapper",
        ),
        "_android_tools": attr.label_list(
            default = [
                "@androidsdk//:files", "@androidsdk//:sdk", "@androidndk//:files",
            ]
        ),
        "_go_tools": attr.label_list(
            default = ["@go_sdk//:files"]
        ),
    },
    output_to_genfiles = True,
    toolchains = [
        "@io_bazel_rules_go//go:toolchain",
    ],
)
