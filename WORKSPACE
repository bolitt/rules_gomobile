workspace(name = "co_znly_rules_gomobile")

load("@co_znly_rules_gomobile//:repositories.bzl", "gomobile_repositories")

gomobile_repositories()

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies(ignore_version_differences = True)

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "rules_jvm_external",
    commit = "e545831479ed112515e3b1fcfff50ad19a623a3c",
    remote = "https://github.com/bazelbuild/rules_jvm_external.git",
    shallow_since = "1572988095 -0500",
)

load("@rules_jvm_external//:defs.bzl", "maven_install")

maven_install(
    name = "android_deps",
    artifacts = [
        "com.android.support:appcompat-v7:27.1.1",
        "com.android.support.constraint:constraint-layout:1.1.2",
        "com.android.support:support-compat:27.1.1",
        "com.android.support:support-annotations:27.1.1",
    ],
    repositories = [
        "https://bintray.com/bintray/jcenter",
        "https://maven.google.com",
        "https://repo1.maven.org/maven2",
    ],
)
