load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def gomobile_repositories():
    maybe(
        http_archive,
        name = "bazel_skylib",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
        ],
        sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
    )
    maybe(
        native.local_repository,
        name = "io_bazel_rules_go",
        path = "../rules_go",
    )
    # maybe(
    #     git_repository,
    #     name = "io_bazel_rules_go",
    #     remote = "https://github.com/bazelbuild/rules_go.git",
    #     commit = "9794aacb240809111dfb9d587d40475b2819310e",
    # )
    maybe(
        git_repository,
        name = "org_golang_x_mobile",
        remote = "https://go.googlesource.com/mobile",
        commit = "6fa95d984e88af20c7b8869192a2345dc560fdbf",
        shallow_since = "1559943918 +0000",
        patch_tool = "git",
        patch_args = ["apply"],
        patches = [
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0001-bind-mark-all-CGo-wrappers-hidden.patch",
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0002-cmd-gobind-replace-the-source-importer-with-the-gc-i.patch",
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0003-add-BUILD.bazel-files.patch",
            "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0004-internal-mobileinit-remove-stderr-redirection.patch",
        ],
    )
    maybe(
        http_archive,
        name = "build_bazel_rules_apple",
        sha256 = "84f34c95e68f65618b54c545f75e2df73559af47fb42ae28b17189fcebb7ed17",
        url = "https://github.com/bazelbuild/rules_apple/releases/download/0.31.1/rules_apple.0.31.1.tar.gz",
    )
    # maybe(
    #     git_repository,
    #     name = "build_bazel_rules_apple",
    #     remote = "https://github.com/bazelbuild/rules_apple.git",
    #     commit = "f6a95e8d0c2bd6fa9f0a6280ef3c4d34c9594513",
    #     shallow_since = "1574206203 -0800",
    #     patches = [
    #         # "@co_znly_rules_gomobile//:third_party/build_bazel_rules_apple/PR-554.patch",
    #     ],
    #     patch_tool = "git",
    #     patch_args = ["apply"],
    # )
    maybe(
        native.android_sdk_repository,
        name = "androidsdk",
    )
    maybe(
        native.android_ndk_repository,
        name = "androidndk",
    )
