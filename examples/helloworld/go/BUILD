# See all details:
# bazel query --output build //examples/helloworld/...
load("@io_bazel_rules_go//go:def.bzl", "go_library")
load("//tools:defs.bzl", "gobind")

package(default_visibility = ["//visibility:public"])

go_library(
    name = "helloworld",
    srcs = ["helloworld.go"],
    importpath = "github.com/example/project/examples/helloworld",
    deps = [
        # Illustate that the exported library can depend on other libraries.
        ":util",
    ]
)

go_library(
    name = "util",
    srcs = ["util.go"],
    importpath = "github.com/example/project/examples/helloworld/util",
)

# Generated targets:
# //examples/helloworld/go:HelloLib@gopath
# //examples/helloworld/go:HelloLib@java
# //examples/helloworld/go:HelloLib@java@jar
# //examples/helloworld/go:HelloLib@java@aar
# //examples/helloworld/go:HelloLib_aar_import
# //examples/helloworld/go:HelloLib@objc@xcframework
# //examples/helloworld/go:HelloLib@objc
gobind(
    name = "HelloLib",
    java_package = "co.znly",
    deps = [":helloworld"],
)
