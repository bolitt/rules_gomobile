load("@bazel_gazelle//:def.bzl", "go_repository")
load("@io_bazel_rules_go//go/private:tools/overlay_repository.bzl", "git_repository", "http_archive")
load("@co_znly_rules_gomobile//third_party:manifest.bzl", "manifest")

def _maybe(repo_rule, name, **kwargs):
  if name not in native.existing_rules():
    repo_rule(name=name, **kwargs)

def gomobile_repositories():
    _maybe(native.http_archive,
        name = "bazel_skylib",
        urls = ["https://codeload.github.com/bazelbuild/bazel-skylib/tar.gz/0.2.0"],
        strip_prefix = "bazel-skylib-0.2.0",
        type = "tar.gz",
    )
    _maybe(git_repository,
        name = "org_golang_x_mobile",
        commit = "5665cf37628bb651a12968646808b67661ad9afb",
        remote = "git@github.com:golang/mobile.git",
        overlay = manifest["org_golang_x_mobile"],
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
