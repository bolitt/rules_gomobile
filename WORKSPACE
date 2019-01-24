workspace(name = "co_znly_rules_gomobile")
load("@co_znly_rules_gomobile//:repositories.bzl", "gomobile_repositories")
gomobile_repositories()

load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains", "go_download_sdk")
go_rules_dependencies()
go_download_sdk(
    name = "go_sdk",
    sdks = {
        "darwin_amd64": ("go1.11.2-znly-1.darwin-amd64.tar.gz", "77b2d3d21f2ac3316188b09f3c3097234e795ddad542ed8fb13413365f0cce24"),
        "linux_amd64": ("go1.11.2-znly-1.linux-amd64.tar.gz", "657dd7a1080cf261900f27f91107074821b4eec2bf4c9dc81bc5661e0b9a6129"),
    },
    urls = ["https://github.com/znly/go/releases/download/go1.11.2-znly-1/{}"],
)
go_register_toolchains()

load("@build_bazel_rules_apple//apple:repositories.bzl", "apple_rules_dependencies")
apple_rules_dependencies()
