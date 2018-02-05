load("@io_bazel_rules_go//go:def.bzl", "go_repository")

def _maybe(repo_rule, name, **kwargs):
  if name not in native.existing_rules():
    repo_rule(name=name, **kwargs)

def gomobile_repositories():
    _maybe(go_repository,
        name = "org_golang_x_mobile",
        commit = "7d170c90b01c0c9d1029751f4ca303b1f1d33732",
        importpath = "golang.org/x/mobile",
        vcs = "git",
        remote = "git@github.com:znly/mobile.git",
    )
    _maybe(native.git_repository,
        name = "build_bazel_rules_apple",
        remote = "https://github.com/znly/rules_apple.git",
        commit = "b2c64f924a2df9108d9b62c82d5650973ee878f1",
    )
