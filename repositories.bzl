load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _maybe(repo_rule, name, **kwargs):
    if name not in native.existing_rules():
        repo_rule(name=name, **kwargs)

def gomobile_repositories():
    _maybe(http_archive,
        name = "bazel_skylib",
        urls = ["https://codeload.github.com/bazelbuild/bazel-skylib/tar.gz/0.6.0"],
        strip_prefix = "bazel-skylib-0.6.0",
        type = "tar.gz",
    )
    _maybe(http_archive,
        name = "io_bazel_rules_go",
        url = "https://github.com/bazelbuild/rules_go/releases/download/0.16.6/rules_go-0.16.6.tar.gz",
        sha256 = "ade51a315fa17347e5c31201fdc55aa5ffb913377aa315dceb56ee9725e620ee",
    )
    _maybe(http_archive,
        name = "org_golang_x_mobile",
        urls = ["https://codeload.github.com/golang/mobile/tar.gz/a42111704963f4f0d1266674e1e97489aa8dcca0"],
        strip_prefix = "mobile-a42111704963f4f0d1266674e1e97489aa8dcca0",
        type = "tar.gz",
        patch_tool = "git",
        patch_args = ["apply"],
        patches = [
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/org_golang_x_mobile.patch",
        ],
    )
    _maybe(http_archive,
        name = "build_bazel_rules_apple",
        urls = ["https://codeload.github.com/bazelbuild/rules_apple/tar.gz/0.13.0"],
        strip_prefix = "rules_apple-0.13.0",
        type = "tar.gz",
    )
    _maybe(native.android_sdk_repository,
        name = "androidsdk",
    )
    _maybe(native.android_ndk_repository,
        name = "androidndk",
    )
