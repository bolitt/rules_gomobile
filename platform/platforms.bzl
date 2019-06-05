_OS = {
    "ios": "darwin",
    "android": "android",
}

_ARCHS = [
    "386",
    "amd64",
    "arm",
    "arm64",
]

_IOS_CPUS = {
    "386": "i386",
    "amd64": "x86_64",
    "arm": "armv7",
    "arm64": "arm64",
}

_ANDROID_CPUS = {
    "386": "x86",
    "amd64": "x86_64",
    "arm": "armeabi-v7a",
    "arm64": "arm64-v8a",
}

def declare_platforms():
    native.constraint_setting(name = "os")
    native.constraint_setting(name = "arch")

    for os, goos in _OS.items():
        native.constraint_value(
            name = "%s_constraint" % os,
            constraint_setting = "os",
            visibility = ["//visibility:public"],
        )
        native.config_setting(
            name = os,
            constraint_values = [
                ":%s_constraint" % os,
            ],
            visibility = ["//visibility:public"],
        )

    for arch in _ARCHS:
        native.constraint_value(
            name = "%s_constraint" % arch,
            constraint_setting = "arch",
            visibility = ["//visibility:public"],
        )
        native.config_setting(
            name = arch,
            constraint_values = [
                ":%s_constraint" % arch,
            ],
            visibility = ["//visibility:public"],
        )

    for os, goos in _OS.items():
        for arch in _ARCHS:
            native.platform(
                name = os + "_" + arch,
                constraint_values = [
                    ":%s_constraint" % os,
                    ":%s_constraint" % arch,
                    "@io_bazel_rules_go//go/toolchain:" + goos,
                    "@io_bazel_rules_go//go/toolchain:" + arch,
                ],
                visibility = ["//visibility:public"],
            )

    native.config_setting(
        name = "multiarch",
        define_values = {
            "gomobile_multiarch": "true",
        },
        visibility = ["//visibility:public"],
    )
