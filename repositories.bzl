load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def gomobile_repositories():
    maybe(
        http_archive,
        name = "bazel_skylib",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
        ],
        sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
    )
    maybe(
        git_repository,
        name = "io_bazel_rules_go",
        remote = "https://github.com/bazelbuild/rules_go.git",
        commit = "1d299a6bc714fedde8f6b461cd7f97732c7eb1a2",
        shallow_since = "1574370922 -0500",
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
        commit = "f6a95e8d0c2bd6fa9f0a6280ef3c4d34c9594513",
        shallow_since = "1574206203 -0800",
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
