load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@io_bazel_rules_go//go:def.bzl", "go_binary")

package(default_visibility = ["//visibility:public"])

go_binary(
    name = "gobind_wrapper",
    srcs = ["gobind_wrapper.go"],
)

bzl_library(
    name = "lib",
    srcs = glob(["*.bzl"]),
)
