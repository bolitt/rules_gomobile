def declare_constraints():
    for cpu in ["i386", "x86_64", "armv7", "arm64"]:
        native.config_setting(
            name = "ios_" + cpu,
            values = {"cpu": "ios_" + cpu},
            visibility = ["//visibility:public"],
        )


PLATFORMS = [
    "ios_x86_64",
    "ios_i386",
    "ios_armv7",
    "ios_arm64",
]
