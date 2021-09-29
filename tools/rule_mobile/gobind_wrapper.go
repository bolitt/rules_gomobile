package main

import (
	"flag"
	"log"
	"os"
	"os/exec"
)

var (
	gomobile    = flag.String("gomobile", "", "")
	checkTarget = flag.String("check_target", "", "Platform target") // Should only be android or ios.
)

const usage = `gomobile should follows the usage:
usage: gomobile bind [-target android|ios|iossimulator|macos|maccatalyst] [-bootclasspath <path>] [-classpath <path>] [-o output] [build flags] [package]

Bind generates language bindings for the package named by the import
path, and compiles a library for the named target system.

The -target flag takes either android (the default), or one or more
comma-delimited Apple platforms (ios, iossimulator, macos, maccatalyst).

For -target android, the bind command produces an AAR (Android ARchive)
file that archives the precompiled Java API stub classes, the compiled
shared libraries, and all asset files in the /assets subdirectory under
the package directory. The output is named '<package_name>.aar' by
default. This AAR file is commonly used for binary distribution of an
Android library project and most Android IDEs support AAR import. For
example, in Android Studio (1.2+), an AAR file can be imported using
the module import wizard (File > New > New Module > Import .JAR or
.AAR package), and setting it as a new dependency
(File > Project Structure > Dependencies).  This requires 'javac'
(version 1.7+) and Android SDK (API level 15 or newer) to build the
library for Android. The environment variable ANDROID_HOME must be set
to the path to Android SDK. Use the -javapkg flag to specify the Java
package prefix for the generated classes.

By default, -target=android builds shared libraries for all supported
instruction sets (arm, arm64, 386, amd64). A subset of instruction sets
can be selected by specifying target type with the architecture name. E.g.,
-target=android/arm,android/386.

For Apple -target platforms, gomobile must be run on an OS X machine with
Xcode installed. The generated Objective-C types can be prefixed with the
-prefix flag.

For -target android, the -bootclasspath and -classpath flags are used to
control the bootstrap classpath and the classpath for Go wrappers to Java
classes.

The -v flag provides verbose output, including the list of packages built.

The build flags -a, -n, -x, -gcflags, -ldflags, -tags, -trimpath, and -work
are shared with the build command. For documentation, see 'go help build'.
`

func run(command string, args ...string) error {
	log.Printf("[gobind_wrapper.go] Running command: \n%v \n[with args]: %v", command, args)
	cmd := exec.Command(command, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func exists(path string) bool {
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

func checkPreconditions() {
	// Print unparse flags flags.Args() to pass as args for subprocess.
	log.Printf("[gobind_wrapper.go] Subprocess flags: flags.Args() = %v", flag.Args())

	// Checks working dir is ok.
	if wd, err := os.Getwd(); err != nil {
		log.Fatalf("Error: %v\n", err)
	} else {
		log.Printf("[gobind_wrapper.go] Current working dir: %v", wd)
	}

	// Preconditions: JAVA_HOME is used for both android and ios.
	if v, ok := os.LookupEnv("JAVA_HOME"); v == "" || !ok {
		log.Fatalf("[gobind_wrapper.go] Requires JAVA_HOME, but got: JAVA_HOME=%s", v)
	} else {
		if !exists(v) {
			log.Fatalf("[gobind_wrapper.go] JAVA_HOME: %s not existed", v)
		}
		log.Printf("[gobind_wrapper.go] JAVA_HOME = %v", v)
	}

	// Preconditions: android.
	if *checkTarget == "android" {
		// Checks ANDROID_HOME, ANDROID_NDK_HOME.
		if v, ok := os.LookupEnv("ANDROID_HOME"); v == "" || !ok || !exists(v) {
			log.Fatalf("[gobind_wrapper.go] Requires ANDROID_HOME (path to the Android SDK), but got: ANDROID_HOME=%s", v)
			if !exists(v) {
				log.Fatalf("[gobind_wrapper.go] ANDROID_HOME: %s not existed", v)
			}
		} else {
			log.Printf("[gobind_wrapper.go] ANDROID_HOME = %v", v)
		}

		if v, ok := os.LookupEnv("ANDROID_NDK_HOME"); v == "" || !ok {
			log.Fatalf("[gobind_wrapper.go] Requires ANDROID_NDK_HOME, but got: ANDROID_NDK_HOME=%s", v)
		} else {
			if !exists(v) {
				log.Fatalf("[gobind_wrapper.go] ANDROID_NDK_HOME: %s not existed", v)
			}
			log.Printf("[gobind_wrapper.go] ANDROID_NDK_HOME = %v", v)
		}
		return
	} else if *checkTarget == "ios" {
		// No extra checks.
		return
	} else {
		panic("Expect flag `checkTarget` to be either android or ios. Got: " + *checkTarget)
	}
}

func main() {
	flag.Parse()
	checkPreconditions()

	if err := run(*gomobile, "init", "-v"); err != nil {
		log.Fatalf("Error: %v\n", err)
	}
	if err := run(*gomobile, flag.Args()...); err != nil {
		log.Fatalf("Error: %v\n", err)
	}
}
