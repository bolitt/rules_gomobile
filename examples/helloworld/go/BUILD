# See all details:
# bazel query --output build //examples/helloworld/...
load("@io_bazel_rules_go//go:def.bzl", "go_library")
load("//rule_mobile:gobind.bzl", "gobind")

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

gobind(
    name = "HelloLib",
    java_package = "co.znly",
    deps = [":helloworld"],
)

# # Alias to aar (generated rule inside :HelloLib).
# alias(
#     name = "HelloLib_aar",
#     actual = ":HelloLib@java@aar",
# )

# # Alias to xcframework (generated rule inside :HelloLib).
# alias(
#     name = "HelloLib_xcframework",
#     actual = ":HelloLib@objc@xcframework",
# )
