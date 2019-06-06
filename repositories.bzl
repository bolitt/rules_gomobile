load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def gomobile_repositories():
    maybe(
        http_archive,
        name = "bazel_skylib",
        url = "https://github.com/bazelbuild/bazel-skylib/releases/download/0.8.0/bazel-skylib.0.8.0.tar.gz",
        sha256 = "2ef429f5d7ce7111263289644d233707dba35e39696377ebab8b0bc701f7818e",
    )
    maybe(
        git_repository,
        name = "io_bazel_rules_go",
        remote = "https://github.com/bazelbuild/rules_go.git",
        commit = "9b2a17d9fa747165f1f08f6229c2a66c74067f0e",
        shallow_since = "1565908622 -0400",
        patches = [
            "//:third_party/io_bazel_rules_go/PR-2181.patch",
        ],
        patch_tool = "git",
        patch_args = ["apply"],
    )
    maybe(
        git_repository,
        name = "org_golang_x_mobile",
        remote = "https://go.googlesource.com/mobile",
        commit = "6fa95d984e88af20c7b8869192a2345dc560fdbf",
        shallow_since = "1559943918 +0000",
        patch_tool = "git",
        patch_args = ["apply"],
        patches = [
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0001-gc-importer.patch",
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0002-bind-mark-all-CGo-wrappers-hidden.patch",
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0003-org_golang_x_mobile.patch",
        ],
    )
    maybe(
        git_repository,
        name = "build_bazel_rules_apple",
        remote = "https://github.com/bazelbuild/rules_apple.git",
        commit = "7adb172f8d4f3c6627e927b151f46dec0127084e",
        shallow_since = "1566328577 -0700",
        patches = [
            "@co_znly_rules_gomobile//:third_party/build_bazel_rules_apple/PR-554.patch",
        ],
        patch_tool = "git",
        patch_args = ["apply"],
    )
    maybe(
        native.android_sdk_repository,
        name = "androidsdk",
    )
    maybe(
        native.android_ndk_repository,
        name = "androidndk",
    )
