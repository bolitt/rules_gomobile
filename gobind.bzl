load("//:java.bzl", "gobind_java")
load("//:objc.bzl", "gobind_objc")

def gobind(name, deps, java_package = "", objc_prefix = "", objc_platform_type = "ios", objc_minimum_os_version = "", tags = [], **kwargs):
    gobind_java(name, deps, java_package, tags, **kwargs)
    gobind_objc(name, deps, objc_prefix, objc_platform_type, objc_minimum_os_version, tags, **kwargs)
