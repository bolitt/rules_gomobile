load("@io_bazel_rules_go//go:def.bzl", "go_repository")

def _maybe(repo_rule, name, **kwargs):
  if name not in native.existing_rules():
    repo_rule(name=name, **kwargs)

def gomobile_repositories():
    _maybe(go_repository,
        name = "org_golang_x_mobile",
        commit = "295aedb6907ae556a3d987e8a0e0ca194932424b",
        importpath = "golang.org/x/mobile",
        vcs = "git",
        remote = "git@github.com:znly/mobile.git",
    )
    _maybe(native.http_archive,
        name = "bazel_skylib",
        urls = ["https://codeload.github.com/bazelbuild/bazel-skylib/tar.gz/0.2.0"],
        strip_prefix = "bazel-skylib-0.2.0",
        type = "tar.gz",
    )
    _maybe(native.http_archive,
        name = "build_bazel_rules_apple",
        urls = ["https://codeload.github.com/bazelbuild/rules_apple/tar.gz/333dadb57b8577092ecfd7fd688327bbbe19de8a"],
        strip_prefix = "rules_apple-333dadb57b8577092ecfd7fd688327bbbe19de8a",
        type = "tar.gz",
    )
    _maybe(native.android_sdk_repository,
        name = "androidsdk",
    )
    _maybe(native.android_ndk_repository,
        name = "androidndk",
    )
