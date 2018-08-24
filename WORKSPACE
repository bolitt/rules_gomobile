workspace(name = "co_znly_rules_gomobile")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "bazel_skylib",
    remote = "https://github.com/bazelbuild/bazel-skylib.git",
    tag = "0.5.0",  # change this to use a different release
)

git_repository(
    name = "co_znly_rules_misc",
    commit = "f44682b6765b5417c7df43c28e4fa6d7b7665ba1",
    remote = "git@github.com:znly/rules_misc.git",
)

maybe(github,
    name = "io_bazel_rules_go",
    author = "znly",
    project = "rules_go",
    commit = "ff9cd1bc1d720e58ec61ae402e5ba7a893e98e01", # feature/core branch
)

load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains()

load("@co_znly_rules_gomobile//:repositories.bzl", "gomobile_repositories")
gomobile_repositories()

load("@co_znly_rules_misc//:repositories.bzl", "declare_repositories")
declare_repositories()
