load("//:common.bzl", "slug")
load("//:gobind_library.bzl", "gobind_library")
load("//:providers.bzl", "GoBindInfo")
load("//platform:transitions.bzl", "go_platform_transition")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_path")

_MODULE_MAP_TPL = """\
module {name} {{
    export *
{headers}
}}
"""

def _normalize_module_name(label):
    parts = [
        s
        for s in [
            label.workspace_name,
            label.package,
            label.name,
        ]
        if s
    ]
    return "_".join(parts).replace("/", "_").replace(".", "_")

def _create_module_map(ctx, gobind_info):
    module_name = _normalize_module_name(ctx.label)
    headers = "\n".join([
        "header \"./%s\"" % paths.relativize(hdr.short_path, ctx.label.package)
        for hdr in gobind_info.objc
    ])
    f = ctx.actions.declare_file("module.modulemap")
    ctx.actions.write(f, _MODULE_MAP_TPL.format(
        name = module_name,
        headers = headers,
    ))
    return f

def _gobind_ios_artifacts_impl(ctx):
    gobind_info = ctx.attr.gobind[GoBindInfo]
    return [
        gobind_info,
        apple_common.new_objc_provider(
            header = depset(gobind_info.objc),
            imported_library = depset(ctx.files.binary),
            force_load_library = depset(ctx.files.binary),
            strict_include = depset(["."]),  # TODO(tianlin): include no longer supported.
            module_map = depset([_create_module_map(ctx, gobind_info)]),
        ),
    ]

gobind_ios_artifacts = rule(
    _gobind_ios_artifacts_impl,
    attrs = {
        "binary": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "gobind": attr.label(
            mandatory = True,
            providers = [GoBindInfo],
        ),
        "_whitelist_function_transition": attr.label(
            default = "@bazel_tools//tools/whitelists/function_transition_whitelist",
        ),
    },
    cfg = go_platform_transition,
)

def _apple_untransition_impl(ctx):
    return [
        DefaultInfo(
            files = depset(ctx.attr.artifacts[0][GoBindInfo].objc),
        ),
    ]

apple_untransition_impl = rule(
    _apple_untransition_impl,
    attrs = {
        "artifacts": attr.label(
            mandatory = True,
            providers = [GoBindInfo],
            cfg = apple_common.multi_arch_split,
        ),
        "minimum_os_version": attr.string(mandatory = True),
        "platform_type": attr.string(
            mandatory = True,
            values = ["ios", "watchos", "tvos"],
        ),
    },
)

def gobind_objc(name, gopath_name, deps, objc_prefix, platform_type, minimum_os_version, tags, **kwargs):
    """Generates gobind for objc."""
    # gopath_name = slug(name, "objc", "gopath")
    gobind_name = slug(name, "gobind", "objc")
    # binary_name = slug(name, "objc", "binary")
    # artifacts_name = slug(name, "objc", "artifacts")
    # objc_library_name = slug(name, "objc")
    # objc_library_hdrs_name = slug(objc_library_name, "hdrs")

    gobind_library(
        name = gobind_name,
        go_path = gopath_name,
        lang = ["go", "objc"],
        objc_prefix = objc_prefix,
        copts = [
            "-xobjective-c",
            "-fmodules",
            "-fobjc-arc",
            "-D__GOBIND_DARWIN__",
        ],
        go_tags = tags + ["ios"],
        deps = deps,
    )
    # copts = kwargs.pop("copts", []) + [
    #     "-xobjective-c",
    #     "-fmodules",
    #     "-fobjc-arc",
    #     "-D__GOBIND_DARWIN__",
    # ]
    # go_binary(
    #     name = binary_name,
    #     srcs = [],
    #     embed = [gobind_name],
    #     out = binary_name + ".a",
    #     deps = deps + [
    #         "@org_golang_x_mobile//bind/java:go_default_library",
    #         "@org_golang_x_mobile//bind/seq:go_default_library",
    #     ],
    #     cgo = True,
    #     copts = copts,
    #     pure = "off",
    #     linkmode = "c-archive",
    #     **kwargs
    # )
    # gobind_ios_artifacts(
    #     name = objc_library_name,
    #     gobind = gobind_name,
    #     binary = binary_name,
    #     visibility = ["//visibility:public"],
    # )
    # apple_untransition_impl(
    #     name = objc_library_hdrs_name,
    #     artifacts = objc_library_name,
    #     platform_type = platform_type,
    #     minimum_os_version = minimum_os_version,
    #     visibility = ["//visibility:public"],
    # )
