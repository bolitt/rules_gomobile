workspace(name = "co_znly_rules_gomobile")

local_repository(
    name = "io_bazel_rules_go",
    path = "/Users/steeve/go/src/github.com/znly/rules_go",
)
load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains()

load("@co_znly_rules_gomobile//:repositories.bzl", "gomobile_repositories")
gomobile_repositories()
