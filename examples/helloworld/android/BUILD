load("@gmaven_rules//:defs.bzl", "gmaven_artifact")

package(default_visibility = ["//visibility:public"])


# bazel build //examples/helloworld/android:app && adb install  bazel-bin/examples/helloworld/android/app.apk
# bazel build //examples/helloworld/android:app --fat_apk_cpu=arm64-v8a,armeabi-v7a
android_binary(
    name = "app",
    srcs = glob([
        "java/**/*.java",
    ]),
    custom_package = "co.znly.rules_gomobile.sampleapp",
    manifest = "AndroidManifest.xml",
    multidex = "native",
    resource_files = glob(["res/**"]),
    deps = [
        "//examples/helloworld/go:HelloLib_aar_import",
        gmaven_artifact("com.android.support:appcompat-v7:aar:27.1.1"),
        gmaven_artifact("com.android.support:support-compat:aar:27.1.1"),
        gmaven_artifact("com.android.support.constraint:constraint-layout:aar:1.1.2"),
    ],
)
