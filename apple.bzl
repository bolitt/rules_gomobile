load("@co_znly_rules_gomobile//:providers.bzl", "GoBindInfo")
load("@io_bazel_rules_go//go:def.bzl", "GoArchive")
load("@bazel_skylib//lib:paths.bzl", "paths")

def _apple_untransition_gobind_hdrs_impl(ctx):
    return [
        DefaultInfo(
            files = depset(ctx.attr.dep[0][GoBindInfo].objc),
        ),
    ]

apple_untransition_gobind_hdrs = rule(
    _apple_untransition_gobind_hdrs_impl,
    attrs = {
        "dep": attr.label(
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

def _create_module_map(ctx, hdrs):
    module_name = _normalize_module_name(ctx.label)
    headers = "\n".join([
        "header \"./%s\"" % paths.relativize(hdr.short_path, ctx.label.package)
        for hdr in hdrs
    ])
    f = ctx.actions.declare_file("module.modulemap")
    ctx.actions.write(f, """\
module {name} {{
    export *
{headers}
}}
""".format(
        name = module_name,
        headers = headers,
    ))
    return f

def _gobind_to_objc_library(ctx):
    gobind_info = ctx.attr.gobind_library[GoBindInfo]
    return [
        gobind_info,
        ctx.attr.gobind_library[DefaultInfo],
        CcInfo(
            compilation_context = cc_common.create_compilation_context(
                headers = depset(gobind_info.objc),
                includes = depset(["."]),
            ),
        ),
        apple_common.new_objc_provider(
            imported_library = depset(ctx.files.deps),
            force_load_library = depset(ctx.files.deps),
            module_map = depset([_create_module_map(ctx, gobind_info.objc)]),
        ),
    ]

gobind_to_objc_library = rule(
    _gobind_to_objc_library,
    attrs = {
        "gobind_library": attr.label(
            mandatory = True,
            providers = [GoBindInfo],
        ),
        "deps": attr.label_list(
            mandatory = True,
            providers = [GoArchive],
        ),
    },
)
