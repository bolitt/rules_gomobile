_OS = {
    "ios": "darwin",
    "android": "android",
}

_CPUS = {
    "i386": "386",
    "x86_64": "amd64",
    "armv7": "arm",
    "arm64": "arm64",
}

def declare_platforms():
    native.constraint_setting(name = "os")
    native.constraint_setting(name = "cpu")

    for os, goos in _OS.items():
        native.constraint_value(
            name = "_" + os,
            constraint_setting = "os",
        )
        native.config_setting(
            name = os,
            constraint_values = [
                "@co_znly_rules_gomobile//platform:_" + os,
            ],
            visibility = ["//visibility:public"],
        )
    for cpu, goarch in _CPUS.items():
        native.constraint_value(
            name = "_" + cpu,
            constraint_setting = "cpu",
        )
        native.config_setting(
            name = cpu,
            constraint_values = [
                "@co_znly_rules_gomobile//platform:_" + cpu,
            ],
            visibility = ["//visibility:public"],
        )

    for os, goos in _OS.items():
        for cpu, goarch in _CPUS.items():
            native.platform(
                name = os + "_" + cpu,
                constraint_values = [
                    "@co_znly_rules_gomobile//platform:_" + os,
                    "@co_znly_rules_gomobile//platform:_" + cpu,
                    "@io_bazel_rules_go//go/toolchain:" + goos,
                    "@io_bazel_rules_go//go/toolchain:" + goarch,
                ],
                visibility = ["//visibility:public"],
            )
