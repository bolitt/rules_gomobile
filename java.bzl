load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load("@co_znly_rules_gomobile//:common.bzl", "slug")
load("@co_znly_rules_gomobile//:gobind_library.bzl", "gobind_library")
load("@co_znly_rules_gomobile//:providers.bzl", "GoBindInfo")
load("@co_znly_rules_gomobile//platform:transitions.bzl", "go_platform_transition")
load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_path")

def _gobind_android_artifacts_impl(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)
    gobind_info = ctx.attr.gobind[GoBindInfo]
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    lib = cc_common.create_library_to_link(
        actions = ctx.actions,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        dynamic_library = ctx.file.binary,
    )

    return [
        DefaultInfo(
            files = depset(gobind_info.java),
        ),
        CcInfo(
            linking_context = cc_common.create_linking_context(
                libraries_to_link = [lib],
            ),
        ),
    ]

gobind_android_artifacts = rule(
    _gobind_android_artifacts_impl,
    attrs = {
        "binary": attr.label(
            allow_single_file = True,
        ),
        "gobind": attr.label(
            mandatory = True,
            providers = [GoBindInfo],
        ),
        "_cc_toolchain": attr.label(
            default = "@bazel_tools//tools/cpp:current_cc_toolchain",
        ),
        "_whitelist_function_transition": attr.label(
            default = "@bazel_tools//tools/whitelists/function_transition_whitelist",
        ),
    },
    cfg = go_platform_transition,
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    fragments = ["cpp"],
)

def gobind_java(name, deps, java_package, tags, **kwargs):
    gopath_name = slug(name, "java", "gopath")
    gobind_name = slug(name, "java", "gobind")
    binary_name = slug(name, "java", "binary")
    artifacts_name = slug(name, "java", "artifacts")
    cc_library_name = slug(name, "java", "cc")
    java_library_name = slug(name, "java", "library")
    android_library_name = slug(name, "android_library")

    go_path(
        name = gopath_name,
        mode = "link",
        include_pkg = True,
        include_transitive = False,
        linkmode = "c-shared",
        deps = deps + [
            "@org_golang_x_mobile//bind:go_default_library",
            "@org_golang_x_mobile//bind/java:go_default_library",
            "@org_golang_x_mobile//bind/seq:go_default_library",
        ],
    )
    gobind_library(
        name = gobind_name,
        go_path = gopath_name,
        lang = ["go", "java"],
        java_package = java_package,
        copts = ["-D__GOBIND_ANDROID__"],
        go_tags = tags,
        deps = deps,
    )
    go_binary(
        name = binary_name,
        embed = [gobind_name],
        deps = deps + [
            "@org_golang_x_mobile//bind/java:go_default_library",
            "@org_golang_x_mobile//bind/seq:go_default_library",
        ],
        out = "libgojni.so",
        pure = "off",
        linkmode = "c-shared",
        **kwargs
    )
    gobind_android_artifacts(
        name = artifacts_name,
        gobind = gobind_name,
        binary = binary_name,
    )
    # java_library_name contains all gobind java classes (with seq and all)
    native.android_library(
        name = java_library_name,
        srcs = [artifacts_name],
        visibility = ["//visibility:public"],
    )

    # # Forward CcInfo from artifacts rule to please android_library
    native.cc_library(
        name = cc_library_name,
        deps = [artifacts_name],
    )
    # android_library_name only contains the libgojni.so file
    native.android_library(
        name = android_library_name,
        exports = [cc_library_name],
        visibility = ["//visibility:public"],
    )
