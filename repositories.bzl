load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _maybe(repo_rule, name, **kwargs):
    if name not in native.existing_rules():
        repo_rule(name=name, **kwargs)

def gomobile_repositories():
    _maybe(http_archive,
        name = "bazel_skylib",
        urls = ["https://codeload.github.com/bazelbuild/bazel-skylib/tar.gz/0.5.0"],
        strip_prefix = "bazel-skylib-0.5.0",
        type = "tar.gz",
    )
    _maybe(http_archive,
        name = "io_bazel_rules_go",
        urls = ["https://codeload.github.com/bazelbuild/rules_go/tar.gz/642cc71323c4e046ee5bd3eaa29f1ca10a4e9e04"],
        strip_prefix = "rules_go-642cc71323c4e046ee5bd3eaa29f1ca10a4e9e04",
        type = "tar.gz",
    )
    _maybe(http_archive,
        name = "org_golang_x_mobile",
        urls = ["https://codeload.github.com/golang/mobile/tar.gz/6621de06e1e9d52c38a8c542770bdbeac9ecfef6"],
        strip_prefix = "mobile-6621de06e1e9d52c38a8c542770bdbeac9ecfef6",
        type = "tar.gz",
        patch_tool = "git",
        patch_args = ["apply"],
        patches = [
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/org_golang_x_mobile.patch",
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0001-bind-genobjc-always-include-ref.h-in-generated-.objc.patch",
        ],
    )
    _maybe(http_archive,
        name = "build_bazel_rules_apple",
        urls = ["https://codeload.github.com/bazelbuild/rules_apple/tar.gz/0.7.0"],
        strip_prefix = "rules_apple-0.7.0",
        type = "tar.gz",
    )
    _maybe(native.android_sdk_repository,
        name = "androidsdk",
    )
    _maybe(native.android_ndk_repository,
        name = "androidndk",
    )
