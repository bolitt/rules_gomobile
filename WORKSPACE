workspace(name = "co_znly_rules_gomobile")
load("@co_znly_rules_gomobile//:repositories.bzl", "gomobile_repositories")
gomobile_repositories()

load("@co_znly_rules_misc//:repositories.bzl", "declare_repositories")
declare_repositories()

load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains", "go_download_sdk")
go_rules_dependencies()

go_download_sdk(
    name = "go_sdk",
    sdks = {
        "darwin_amd64": ("go1.10.4-jni.darwin-amd64.tar.gz", "1096529e3ddc081ad7f9f6c902ee9da36cdcc74daece7287bc3d5502033b8079"),
        "linux_amd64": ("go1.10.4-jni.linux-amd64.tar.gz", "91c43d52bbccb3fba5e0bc9efb0ddfafe6f558b1f499a33aab245b107d3349c0"),
    },
    urls = ["https://github.com/znly/go/releases/download/go1.10.4-jni/{}"],
)

go_register_toolchains()

load("@build_bazel_rules_apple//apple:repositories.bzl", "apple_rules_dependencies")
apple_rules_dependencies()
