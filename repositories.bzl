load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _maybe(repo_rule, name, **kwargs):
    if name not in native.existing_rules():
        repo_rule(name = name, **kwargs)

def gomobile_repositories():
    _maybe(
        http_archive,
        name = "bazel_skylib",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/0.8.0/bazel-skylib.0.8.0.tar.gz"],
        sha256 = "2ef429f5d7ce7111263289644d233707dba35e39696377ebab8b0bc701f7818e",
    )
    _maybe(
        http_archive,
        name = "io_bazel_rules_go",
        url = "https://github.com/bazelbuild/rules_go/releases/download/0.18.3/rules_go-0.18.3.tar.gz",
        sha256 = "86ae934bd4c43b99893fc64be9d9fc684b81461581df7ea8fc291c816f5ee8c5",
    )
    _maybe(
        http_archive,
        name = "org_golang_x_mobile",
        urls = ["https://codeload.github.com/golang/mobile/tar.gz/3e0bab5405d63a8f5dd9d9764a24c8e5ac4997fa"],
        strip_prefix = "mobile-3e0bab5405d63a8f5dd9d9764a24c8e5ac4997fa",
        type = "tar.gz",
        patch_tool = "git",
        patch_args = ["apply"],
        patches = [
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/org_golang_x_mobile.patch",
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0001-bind-mark-all-CGo-wrappers-hidden.patch",
        ],
    )
    _maybe(
        http_archive,
        name = "build_bazel_rules_apple",
        urls = ["https://github.com/bazelbuild/rules_apple/releases/download/0.14.0/rules_apple.0.14.0.tar.gz"],
        sha256 = "8f32e2839fba28d549e1670dbed83606dd339a9f7489118e481814d61738270f",
        type = "tar.gz",
    )
    _maybe(
        native.android_sdk_repository,
        name = "androidsdk",
    )
    _maybe(
        native.android_ndk_repository,
        name = "androidndk",
    )
