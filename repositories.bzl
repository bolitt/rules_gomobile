load("@bazel_gazelle//:deps.bzl", "go_repository")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

DIRECTIVES = [
    "gazelle:go_visibility @co_znly_rules_gomobile//:__subpackages__",
]

def go_repositories():
    """go_repositories."""
    go_repository(
        name = "com_github_burntsushi_xgb",
        importpath = "github.com/BurntSushi/xgb",
        sum = "h1:1BDTz0u9nC3//pOCMdNH+CiXJVYJh5UQNCOBG7jbELc=",
        version = "v0.0.0-20160522181843-27f122750802",
    )
    go_repository(
        name = "com_github_yuin_goldmark",
        importpath = "github.com/yuin/goldmark",
        sum = "h1:OtISOGfH6sOWa1/qXqqAiOIAO6Z5J3AEAE18WAq6BiQ=",
        version = "v1.4.0",
    )
    go_repository(
        name = "org_golang_x_crypto",
        importpath = "golang.org/x/crypto",
        sum = "h1:ObdrDkeb4kJdCP557AjRjq69pTHfNouLtWZG7j9rPN8=",
        version = "v0.0.0-20191011191535-87dc89f01550",
    )
    go_repository(
        name = "org_golang_x_exp",
        importpath = "golang.org/x/exp",
        sum = "h1:estk1glOnSVeJ9tdEZZc5mAMDZk5lNJNyJ6DvrBkTEU=",
        version = "v0.0.0-20190731235908-ec7cb31e5a56",
    )
    go_repository(
        name = "org_golang_x_image",
        importpath = "golang.org/x/image",
        sum = "h1:+qEpEAPhDZ1o0x3tHzZTQDArnOixOzGD9HUJfcg0mb4=",
        version = "v0.0.0-20190802002840-cff245a6509b",
    )
    go_repository(
        name = "org_golang_x_mod",
        importpath = "golang.org/x/mod",
        sum = "h1:Gz96sIWK3OalVv/I/qNygP42zyoKp3xptRVCWRFEBvo=",
        version = "v0.4.2",
    )
    go_repository(
        name = "org_golang_x_net",
        importpath = "golang.org/x/net",
        sum = "h1:20cMwl2fHAzkJMEA+8J4JgqBQcQGzbisXo31MIeenXI=",
        version = "v0.0.0-20210805182204-aaa1db679c0d",
    )
    go_repository(
        name = "org_golang_x_sync",
        importpath = "golang.org/x/sync",
        sum = "h1:5KslGYwFpkhGh+Q16bwMP3cOontH8FOep7tGV86Y7SQ=",
        version = "v0.0.0-20210220032951-036812b2e83c",
    )
    go_repository(
        name = "org_golang_x_sys",
        importpath = "golang.org/x/sys",
        sum = "h1:QOQNt6vCjMpXE7JSK5VvAzJC1byuN3FgTNSBwf+CJgI=",
        version = "v0.0.0-20210925032602-92d5a993a665",
    )
    go_repository(
        name = "org_golang_x_mobile",
        importpath = "golang.org/x/mobile",
        sum = "h1:CyFUjc175y/mbMjxe+WdqI72jguLyjQChKCDe9mfTvg=",
        version = "v0.0.0-20210924032853-1c027f395ef7",
        patches = [
            "@co_znly_rules_gomobile//third_party/org_golang_x_mobile:all.patch",
        ],
    )
    go_repository(
        name = "org_golang_x_term",
        importpath = "golang.org/x/term",
        sum = "h1:v+OssWQX+hTHEmOBgwxdZxK4zHq3yOs8F9J7mk0PY8E=",
        version = "v0.0.0-20201126162022-7de9c90e9dd1",
    )
    go_repository(
        name = "org_golang_x_text",
        importpath = "golang.org/x/text",
        sum = "h1:aRYxNxv6iGQlyVaZmk6ZgYEDa+Jg18DxebPSrd6bg1M=",
        version = "v0.3.6",
    )
    go_repository(
        name = "org_golang_x_tools",
        importpath = "golang.org/x/tools",
        sum = "h1:SIasE1FVIQOWz2GEAHFOmoW7xchJcqlucjSULTL0Ag4=",
        version = "v0.1.6",
    )
    go_repository(
        name = "org_golang_x_xerrors",
        importpath = "golang.org/x/xerrors",
        sum = "h1:go1bK/D/BFZV2I8cIQd1NKEZ+0owSTG1fDTci4IqFcE=",
        version = "v0.0.0-20200804184101-5ec99f83aff1",
    )

def gomobile_repositories():
    """gomobile_repositories."""
    # maybe(
    #     http_archive,
    #     name = "bazel_skylib",
    #     urls = [
    #         "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
    #         "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
    #     ],
    #     sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
    # )
    # maybe(
    #     http_archive,
    #     name = "io_bazel_rules_go",
    #     urls = [
    #         "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/v0.20.2/rules_go-v0.20.2.tar.gz",
    #         "https://github.com/bazelbuild/rules_go/releases/download/v0.20.2/rules_go-v0.20.2.tar.gz",
    #     ],
    #     sha256 = "b9aa86ec08a292b97ec4591cf578e020b35f98e12173bbd4a921f84f583aebd9",
    #     patches = [
    #         "//:third_party/io_bazel_rules_go/PR-2181.patch",
    #     ],
    #     patch_tool = "git",
    #     patch_args = ["apply"],
    # )
    # maybe(
    #     git_repository,
    #     name = "org_golang_x_mobile",
    #     remote = "https://go.googlesource.com/mobile",
    #     commit = "6fa95d984e88af20c7b8869192a2345dc560fdbf",
    #     shallow_since = "1559943918 +0000",
    #     patch_tool = "git",
    #     patch_args = ["apply"],
    #     patches = [
    #         "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0001-bind-mark-all-CGo-wrappers-hidden.patch",
    #         "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0002-cmd-gobind-replace-the-source-importer-with-the-gc-i.patch",
    #         "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0003-add-BUILD.bazel-files.patch",
    #         "@co_znly_rules_gomobile//third_party:org_golang_x_mobile/0004-internal-mobileinit-remove-stderr-redirection.patch",
    #     ],
    # )
    # maybe(
    #     git_repository,
    #     name = "build_bazel_rules_apple",
    #     remote = "https://github.com/bazelbuild/rules_apple.git",
    #     commit = "f6a95e8d0c2bd6fa9f0a6280ef3c4d34c9594513",
    #     shallow_since = "1574206203 -0800",
    #     patches = [
    #         "@co_znly_rules_gomobile//:third_party/build_bazel_rules_apple/PR-554.patch",
    #     ],
    #     patch_tool = "git",
    #     patch_args = ["apply"],
    # )
    # maybe(
    #     native.android_sdk_repository,
    #     name = "androidsdk",
    # )
    # maybe(
    #     native.android_ndk_repository,
    #     name = "androidndk",
    # )
