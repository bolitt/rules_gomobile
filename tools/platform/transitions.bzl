_ANDROID_CPUS_TO_PLATFORMS = {
    "arm64-v8a": "@io_bazel_rules_go//go/toolchain:android_arm64_cgo",
    "armeabi-v7a": "@io_bazel_rules_go//go/toolchain:android_arm_cgo",
    "x86": "@io_bazel_rules_go//go/toolchain:android_386_cgo",
    "x86_64": "@io_bazel_rules_go//go/toolchain:android_amd64_cgo",
}

_IOS_CPUS_TO_PLATFORMS = {
    "ios_arm64": "@io_bazel_rules_go//go/toolchain:ios_arm64_cgo",
    "ios_armv7": "@io_bazel_rules_go//go/toolchain:ios_arm_cgo",
    "ios_i386": "@io_bazel_rules_go//go/toolchain:ios_386_cgo",
    "ios_x86_64": "@io_bazel_rules_go//go/toolchain:ios_amd64_cgo",
}

def _go_platform_transition_impl(settings, attr):
    platform = ""
    cpu = settings["//command_line_option:cpu"]
    crosstool_top = settings["//command_line_option:crosstool_top"]
    if str(crosstool_top) == "//external:android/crosstool" or crosstool_top.workspace_name == "androidndk":
        platform = _ANDROID_CPUS_TO_PLATFORMS[cpu]
    elif cpu in _IOS_CPUS_TO_PLATFORMS:
        platform = _IOS_CPUS_TO_PLATFORMS[cpu]
    return {
        "//command_line_option:platforms": platform,
    }

go_platform_transition = transition(
    implementation = _go_platform_transition_impl,
    inputs = [
        "//command_line_option:cpu",
        "//command_line_option:crosstool_top",
    ],
    outputs = [
        "//command_line_option:platforms",
    ],
)
