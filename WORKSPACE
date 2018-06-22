workspace(name = "co_znly_rules_gomobile")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "bazel_skylib",
    remote = "https://github.com/bazelbuild/bazel-skylib.git",
    tag = "0.5.0",  # change this to use a different release
)

local_repository(
    name = "io_bazel_rules_go",
    path = "../rules_go",
)

load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains()

load("@co_znly_rules_gomobile//:repositories.bzl", "gomobile_repositories")
gomobile_repositories()
