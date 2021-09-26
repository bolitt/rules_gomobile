workspace(name = "co_znly_rules_gomobile")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_skylib",
    urls = [
        "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
    ],
    sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
)
load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")
bazel_skylib_workspace()

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "8e968b5fcea1d2d64071872b12737bbb5514524ee5f0a4f54f5920266c261acb",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.28.0/rules_go-v0.28.0.zip",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.28.0/rules_go-v0.28.0.zip",
    ],
)

http_archive(
    name = "build_bazel_rules_apple",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_apple/releases/download/v0.31.3/rules_apple-0.31.3.tar.gz",
        "https://github.com/bazelbuild/rules_apple/archive/refs/tags/0.31.3.tar.gz",
    ],
    strip_prefix = "rules_apple-0.31.3",
    sha256 = "d6735ed25754dbcb4fce38e6d72c55b55f6afa91408e0b72f1357640b88bb49c",
)

# path = "/path/to/sdk", Optional. Can be omitted if `ANDROID_HOME` environment variable is set.
android_sdk_repository(
    name = "androidsdk",
    api_level = 29,
)

# path = "/path/to/ndk", Optional. Can be omitted if `ANDROID_NDK_HOME` environment variable is set.
android_ndk_repository(
    name = "androidndk",
    api_level = 21,
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

# https://github.com/bazelbuild/bazel-gazelle
local_repository(
    name = "bazel_gazelle",
    path = "third_party/bazel-gazelle",
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains(go_version = "1.17")

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
load("//:repositories.bzl", "go_repositories")

# gazelle:repository_macro repositories.bzl%go_repositories
go_repositories()

gazelle_dependencies()

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

RULES_JVM_EXTERNAL_TAG = "4.1"
RULES_JVM_EXTERNAL_SHA = "f36441aa876c4f6427bfb2d1f2d723b48e9d930b62662bf723ddfb8fc80f0140"

http_archive(
    name = "rules_jvm_external",
    sha256 = RULES_JVM_EXTERNAL_SHA,
    strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % RULES_JVM_EXTERNAL_TAG,
)

# Google Maven Repository
_GMAVEN_TAG = "20181212-2"

http_archive(
    name = "gmaven_rules",
    sha256 = "33027de68db6a49a352f83808fa9898c4930d39aa6fb0edc6bb3d3eec6e2bc7d",
    strip_prefix = "gmaven_rules-%s" % _GMAVEN_TAG,
    url = "https://github.com/bazelbuild/gmaven_rules/archive/%s.tar.gz" % _GMAVEN_TAG,
)

load("@gmaven_rules//:gmaven.bzl", "gmaven_rules")

gmaven_rules()
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/com/android/support/constraint/constraint-layout/1.1.2/constraint-layout-1.1.2.aar) = 839a7e16fc50adfabaa8cb753e675ed63f94e1e91ba9115ce43b0d6a37fe8aa6
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/com/android/support/support-compat/27.1.1/support-compat-27.1.1.aar) = 880ce01ff5be42b233ff8ec0c61cefb7dc3dc9500fea9e24423214813ac27ea2
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/com/android/support/appcompat-v7/27.1.1/appcompat-v7-27.1.1.aar) = 0c7808fbbc5838d831e32e3c0a6f84e1f2c981deb8f11e010650f2b57923a335
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/com/android/support/support-annotations/27.1.1/support-annotations-27.1.1.jar) = 3365960206c3d2b09e845f555e7f88f8effc8d2f00b369e66c4be384029299cf
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/com/android/support/support-fragment/27.1.1/support-fragment-27.1.1.aar) = ec72d6ac36a1a0e6523bbddba33d73ffad070b9b3dd246cc44d8727a41ddb5e6
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/com/android/support/support-core-utils/27.1.1/support-core-utils-27.1.1.aar) = 61036832c54e8701aae954fc3bf96d1d80bf8d9dd531bff77d72def456ba087a
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/android/arch/lifecycle/runtime/1.1.0/runtime-1.1.0.aar) = 094fd793924dd6a5136753e599ac8174a8147f4a401386b694ba7d818c223e2e
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/com/android/support/animated-vector-drawable/27.1.1/animated-vector-drawable-27.1.1.aar) = 59670473f6e98fda792f7bef25dd7292b0a3106031c7a5e30eb020bf26f077bd
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/com/android/support/support-annotations/26.1.0/support-annotations-26.1.0.jar) = 99d6199ad5a09a0e5e8a49a4cc08f818483ddcfd7eedea2f9923412daf982309
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/com/android/support/support-vector-drawable/27.1.1/support-vector-drawable-27.1.1.aar) = 1c0f421114cf4627cf208776d6eb4f76340c78b7e96fe6e12b3e6eb950caf1b9
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/android/arch/core/common/1.1.0/common-1.1.0.jar) = d34824b794bc92ff8f647a9bb13a7c73de920de5b47075b5d2c4f0770e9b8bfd
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/android/arch/lifecycle/viewmodel/1.1.0/viewmodel-1.1.0.aar) = 6407c93a5ea9850661dca42a0068d6f3deccefd7228ee69bae1c35d70cbc2557
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/android/arch/lifecycle/common/1.1.0/common-1.1.0.jar) = 614e31cfd33255dc4d5f5d8e62cfa6be2fbbc2a35643a79dc3ed008004c30807
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/com/android/support/support-core-ui/27.1.1/support-core-ui-27.1.1.aar) = a3ae20e6d5dffba69ac97b99846d2738003af8563843d5f3c9dc4c35b4804241
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/com/android/support/constraint/constraint-layout-solver/1.1.2/constraint-layout-solver-1.1.2.jar) = 55f82d93e188b5183b71f4f3bace5725c900b737c3514c841114e225627ff88f
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/android/arch/lifecycle/livedata-core/1.1.0/livedata-core-1.1.0.aar) = 14e57ff8ffb65a80c7e72d91f2076acccdaf2970f234c6261e03a6127eb5206b
# INFO: SHA256 (https://dl.google.com/dl/android/maven2/android/arch/core/runtime/1.1.0/runtime-1.1.0.aar) = 83400f7575bcfb8a2eeec64e05590f037bfaed1e56aa3a4214d20e55878445e3
