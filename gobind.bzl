load("@co_znly_rules_gomobile//:java.bzl", "gobind_java")
load("@co_znly_rules_gomobile//:objc.bzl", "gobind_objc")

def gobind(name, deps, java_package = "", objc_prefix = "", tags = [], **kwargs):
    gobind_java(name, deps, java_package, tags, **kwargs)
    gobind_objc(name, deps, objc_prefix, tags, **kwargs)
