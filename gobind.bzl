load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_path", "GoLibrary", "GoSource", "GoPath", "go_context")
load("@co_znly_rules_gomobile//:common.bzl", "slug", "gen_include_path")
load("@co_znly_rules_gomobile//:common.bzl", "pkg_short", "genpath", "run_ex")

_SUPPORT_FILES_JAVA = [
    "go/error.java",
    "go/LoadJNI.java",
]

_OBJC_ATTRS = {
    "hdrs": None,
    "asset_catalogs": None,
    "bundles": None,
    "datamodels": None,
    "includes,": None,
    "sdk_dylibs": None,
    "sdk_frameworks": None,
    "sdk_includes": None,
    "storyboards": None,
    "strings": None,
    "structured_resources,": None,
    "textual_hdrs,": None,
    "weak_sdk_frameworks": None,
    "xibs": None,
}

def _filter(l):
    return [v for v in l if v]

def _extract_objc_opts(kwargs):
    objcopts = {}
    for key in kwargs.keys():
        if key.startswith("objc_"):
            arg = key[len("objc_"):]
            if arg not in _OBJC_ATTRS:
                fail("Forbidden objc_library parameter: " + arg)
            value = kwargs.pop(key)
            objcopts[arg] = value
    return objcopts

def _java_classname(pkg):
    return "/".join(pkg.split("."))

def _append_gen_file(ctx, go, og, *f):
    og.append(go.actions.declare_file(genpath(ctx, *f)))

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

        darwin_hdr =  pkg_short_ + "_darwin.h",
        darwin_m = objc_prefix_ + pkg_short_title + "_darwin.m",
        darwin_public_hdr = objc_prefix_ + pkg_short_title + ".objc.h",
    )

def _gen_pkg_files(ctx, go, pkg, outputs):
    files = _gen_filenames(pkg, ctx.attr.java_package, ctx.attr.objc_prefix)
    outputs.cc_hdrs_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.hdr)))
    for filename in [files.darwin_hdr, files.darwin_m]:
        outputs.darwin_cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))
    outputs.darwin_public_hdrs.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.darwin_public_hdr)))

    for filename in [files.android_hdr, files.android_c]:
        outputs.android_cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))
    outputs.android_java_files.append(go.actions.declare_file(genpath(ctx, "java", files.android_class)))

    outputs.go_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.go_main)))

def _gen_universe_files(ctx, go, outputs):
    files = _gen_filenames("universe", "", "")
    outputs.cc_hdrs_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.hdr)))
    for filename in [files.darwin_hdr, files.darwin_m]:
        outputs.darwin_cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))
    outputs.darwin_public_hdrs.append(go.actions.declare_file(genpath(ctx, "src", "gobind", files.darwin_public_hdr)))
    for filename in [files.android_hdr, files.android_c]:
        outputs.android_cc_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", filename)))
    outputs.android_java_files.append(go.actions.declare_file(genpath(ctx, "java", "go", "Universe.java")))

def _gen_seq_files(ctx, go, outputs):
    outputs.cc_hdrs_files.append(go.actions.declare_file(genpath(ctx, "src", "gobind", "seq.h")))
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
        for type_ in _filter(types_str.split(",")):
            outputs.android_java_files.append(go.actions.declare_file(genpath(ctx, "java", _java_classname(ctx.attr.java_package), pkg_short_, type_ + ".java")))

def _gobind_multiarch_artefacts_impl(ctx):
    cpu = ctx.fragments.cpp.cpu
    binary_basename = ctx.file.binary.basename[:-len(ctx.file.binary.extension)] + ctx.attr.extension
    pkg = ctx.attr.binary.label.package
    if pkg:
        pkg += "/"
    outfile_name = "%s/%s%s" % (cpu, pkg, binary_basename)
    outfile = ctx.actions.declare_file(outfile_name)

    ctx.actions.run_shell(
        outputs = [outfile],
        command = """\
        find bazel-out -type f -path 'bazel-out/{cpu}-*/bin/{pkg}*/{binary}' -exec cp -f {{}} {outfile} \;
        """.format(
            cpu = cpu,
            pkg = pkg,
            binary = binary_basename,
            outfile = outfile.path,
        ),
        execution_requirements = {
            "no-sandbox": "1",
        },
    )
    return [
        DefaultInfo(
            files = depset([outfile]),
        ),
    ]

gobind_multiarch_artefacts = rule(
    _gobind_multiarch_artefacts_impl,
    attrs = {
        "binary": attr.label(allow_single_file = True),
        "extension": attr.string(mandatory = True),
    },
    output_to_genfiles = True,
    fragments = ["cpp"],
)

def _gobind_impl(ctx):
    """_gobind_impl"""
    go = go_context(ctx)
    gopath = ctx.attr.go_path[GoPath]

    packages = [d[GoLibrary].importpath for d in ctx.attr.deps]

    outputs = struct(
        go_main = [],
        go_files = [],
        cc_files = [],
        cc_hdrs_files = [],
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
        outputs.cc_hdrs_files + \
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
            "-javapkg=" + ctx.attr.java_package,
            "-prefix=" + ctx.attr.objc_prefix,
            "-tags=" + ",".join(ctx.attr.go_tags),
            "-outdir=" + "/".join([
                ctx.genfiles_dir.path,
                ctx.label.package,
                ctx.label.name,
            ]),
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
            cc_hdrs_files = outputs.cc_hdrs_files,
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
        "go_tags": attr.string_list(),
        "java_package": attr.string(mandatory = True),
        "objc_prefix": attr.string(
            mandatory = False,
            default = "",
        ),
        "_go_context_data": attr.label(
            default = "@io_bazel_rules_go//:go_context_data",
        ),
        "_gobind": attr.label(
            executable = True,
            cfg = "host",
            default = "@org_golang_x_mobile//cmd/gobind:gobind",
        ),
    },
    output_to_genfiles = True,
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)

def _gobind_java(name, groups, gobind_gen, deps, **kwargs):
    gomobile_main_cc_library = slug(name, "java", "gomobile_main_cc_library")
    gomobile_main_library = slug(name, "java", "gomobile_main_library")
    # gomobile_main_binary = slug(name, "java", "gomobile_main_binary")
    gomobile_main_binary = "gojni"
    gomobile_main_binary_multiarch = slug(name, "java", "gomobile_main_binary", "multiarch")
    gomobile_main_binary_cc_import = slug(name, "java", "cc_import")
    gomobile_main_binary_cc_library = slug(name, "java", "cc_library")
    android_library_name = slug(name, "android_library")

    native.cc_library(
        name = gomobile_main_cc_library,
        hdrs = [
            groups["cc_hdrs_files"],
        ],
        includes = [gobind_gen + "/src/gobind"],
        defines = [
            "__GOBIND_ANDROID__",
        ],
        visibility = ["//visibility:private"],
    )

    go_library(
        name = gomobile_main_library,
        srcs = [
            groups["go_files"],
            groups["cc_files"],
            groups["android_cc_files"],
            groups["android_go_files"],
        ],
        cgo = True,
        cdeps = [
            gomobile_main_cc_library,
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
        **kwargs
    )

    # ===================================

    gobind_multiarch_artefacts(
        name = gomobile_main_binary_multiarch,
        binary = gomobile_main_binary,
        extension = "so",
    )

    native.cc_import(
        name = gomobile_main_binary_cc_import,
        shared_library = select({
            "@co_znly_rules_gomobile//platform:multiarch": gomobile_main_binary_multiarch,
            "//conditions:default": gomobile_main_binary,
        }),
    )
    native.cc_library(
        name = gomobile_main_binary_cc_library,
        deps = [gomobile_main_binary_cc_import],
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

def _gobind_objc(name, groups, gobind_gen, deps, objcopts, **kwargs):
    gomobile_bind_library = slug(name, "objc", "gomobile_bind_library")
    gomobile_main_cc_library = slug(name, "objc", "gomobile_main_cc_library")
    gomobile_main_library = slug(name, "objc", "gomobile_main_library")
    gomobile_main_binary = slug(name, "objc", "gomobile_main_binary")

    native.cc_library(
        name = gomobile_main_cc_library,
        hdrs = [
            groups["cc_hdrs_files"],
        ],
        includes = [gobind_gen + "/src/gobind"],
        defines = [
            "__GOBIND_DARWIN__",
        ],
        visibility = ["//visibility:private"],
    )

    go_library(
        name = gomobile_main_library,
        srcs = [
            groups["go_files"],
            groups["cc_files"],
            groups["darwin_go_files"],
            groups["darwin_cc_files"],
            groups["darwin_public_hdrs"],
        ],
        cgo = True,
        objc = True,
        copts = [
            "-x", "objective-c",
            "-fmodules",
            "-fobjc-arc",
            "-Wno-shorten-64-to-32",
        ],
        cdeps = [
            gomobile_main_cc_library,
        ],
        objc_enable_modules = 1,
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
        linkmode = "c-archive",
        visibility = ["//visibility:public"],
        **kwargs
    )

    # objc deps can only have underscores and dashes
    native.objc_import(
        name = slug(name, "objc", token="_"),
        hdrs = [groups["darwin_public_hdrs"]],
        alwayslink = 1,
        includes = ["."],
        archives = [gomobile_main_binary],
        visibility = ["//visibility:public"],
        **objcopts
    )

    native.filegroup(
        name = slug(name, "objc_hdrs", token="_"),
        srcs = [gobind_gen],
        output_group = "darwin_public_hdrs",
        visibility = ["//visibility:public"],
    )

    return gomobile_main_binary

def gobind(name, deps, java_package="", objc_prefix="", tags=[], **kwargs):
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
        java_package = java_package,
        objc_prefix = objc_prefix,
        go_tags = tags + select({
            "@io_bazel_rules_go//go/platform:darwin": ["ios"],
            "//conditions:default": [],
        }),
        deps = _deps,
    )

    go_files = slug(name, "go_files")
    go_main = slug(name, "go_main")
    cc_files = slug(name, "cc_files")
    cc_hdrs_files = slug(name, "cc_files")
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
        "cc_hdrs_files",
        "android_go_files",
        "android_cc_files",
        "android_java_files",
        "darwin_go_files",
        "darwin_cc_files",
        "darwin_public_hdrs",
    ]
    groups = {}

    for group_name in _group_names:
        target_group_name = slug(name, group_name)
        groups[group_name] = target_group_name
        native.filegroup(
            name = target_group_name,
            srcs = [gobind_gen],
            output_group = group_name,
        )

    objcopts = _extract_objc_opts(kwargs)
    _gobind_java(name, groups, gobind_gen, _deps, **kwargs)
    _gobind_objc(name, groups, gobind_gen, _deps, objcopts, **kwargs)
