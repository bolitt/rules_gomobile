# rules_gomobile
gomobile bind rules for Bazel.

# Environment
To build Android app, we need the pre-installed Android, and set `ANDROID_HOME` and `ANDROID_NDK_HOME`.

For example,

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk-bundle/android-ndk-r21e"
```

If you want one command to install Android SDK and NDK, please check this standalone script: https://github.com/google/mediapipe/blob/master/setup_android_sdk_and_ndk.sh.

We also use the local JDK which is used by `bazel` too. `JAVA_HOME` is detected automatically, if you can run `bazel` directly.

# Build: Examples

To build Gobind for Android (`<Lib>@java`) and iOS (`<Lib>@objc`), and then export respective packages: 
aar (`<Lib>_aar_import`) and xcframwork (`<Lib>@objc@xcframework`).

```bash
# To build all binding files.
bazel build //examples/helloworld:all

# To build HelloLib.aar for Android.
bazel build //examples/helloworld/go:HelloLib_aar_import

# To build HelloLib.xcframework for iOS
bazel build //examples/helloworld/go:HelloLib@objc@xcframework

# Buildable targets:
# //examples/helloworld/go:HelloLib_aar_import
# //examples/helloworld/go:HelloLib@objc@xcframework
# //examples/helloworld/go:HelloLib@objc
# //examples/helloworld/go:HelloLib@java@jar
# //examples/helloworld/go:HelloLib@java@aar
# //examples/helloworld/go:HelloLib@java
# //examples/helloworld/go:HelloLib@gopath
```

To build the Android app directly, use:

```bash
# To build Android app.
bazel build //examples/helloworld/android:app

# Install apk via adb.
adb install bazel-bin/examples/helloworld/android/app.apk
```

# Acknowledgment

The code is ported from https://github.com/znly/rules_gomobile. Since the repo hasn't been updated for 2 years and used old Golang and bazel (1.2.1) versions, we couldn't make it work initially.

Now the repo has been refactored at large scale.

- Changed the Go generator from command [`gobind`](https://pkg.go.dev/golang.org/x/mobile/cmd/gobind) to [`gomobile`](https://golang.org/wiki/Mobile) for Android/iOS. (See pkg: https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile for details)
- Used [`gazelle`](https://github.com/bazelbuild/bazel-gazelle) to manage Go packages.
- Simplified rules.
