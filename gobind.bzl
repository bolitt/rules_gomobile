load("//:common.bzl", "slug")
load("//:java.bzl", "gobind_java")
load("//:objc.bzl", "gobind_objc")
load("@io_bazel_rules_go//go:def.bzl", "go_path")

def gobind(name, deps, java_package = "", objc_prefix = "", objc_platform_type = "ios", objc_minimum_os_version = "", tags = [], **kwargs):
    """Creates gobind rules for java and objc."""
    gopath_name = slug(name, "gopath")
    go_path(
        name = gopath_name,
        mode = "link",
        include_pkg = True,
        include_transitive = True,
        deps = deps + [
            # For command line.
            "@org_golang_x_mobile//cmd/gomobile:gomobile",
            "@org_golang_x_mobile//cmd/gobind:gobind",
            # For bind.
            "@org_golang_x_mobile//bind:go_default_library",
            "@org_golang_x_mobile//bind/java:go_default_library",
            "@org_golang_x_mobile//bind/seq:go_default_library",
            "@org_golang_x_mobile//bind/objc:go_default_library",
            # For other resources.
            "@org_golang_x_mobile//asset:go_default_library",
            "@org_golang_x_mobile//app:go_default_library",
            "@org_golang_x_mobile//gl:go_default_library",
            "@org_golang_x_mobile//geom:go_default_library",
            "@org_golang_x_sys//execabs:go_default_library",
            "@org_golang_x_tools//go/packages:go_default_library",
            "@org_golang_x_tools//go/gcexportdata:go_default_library",
            "@org_golang_x_xerrors//:go_default_library",
        ],
    )
    gobind_java(name, gopath_name, deps, java_package, tags, **kwargs)
    gobind_objc(name, gopath_name, deps, objc_prefix, objc_platform_type, objc_minimum_os_version, tags, **kwargs)
