package main

import (
	"flag"
	"log"
	"os"
	"os/exec"
)

var (
	gomobile = flag.String("gomobile", "", "")

	outaar  = flag.String("o", "", "")
	v       = flag.Bool("v", true, "")
	target  = flag.String("target", "", "") // Should only be android or ios.
	codepkg = flag.String("codepkg", "", "")
)

func run(command string, args ...string) error {
	log.Printf("[gobind_wrapper.go] Running command: \n%v \n[with args]: %v", command, args)
	cmd := exec.Command(command, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func checkPrecondition() {
	// Preconditions: JAVA_HOME is used for both android and ios.
	if v, ok := os.LookupEnv("JAVA_HOME"); v == "" || !ok {
		log.Fatalf("[gobind_wrapper.go] Requires JAVA_HOME, but got: JAVA_HOME=%s", v)
	}

	// Preconditions: android.
	if *target == "android" {
		// Checks ANDROID_HOME, ANDROID_NDK_HOME and JAVA_HOME
		if v, ok := os.LookupEnv("ANDROID_HOME"); v == "" || !ok {
			log.Fatalf("[gobind_wrapper.go] Requires ANDROID_HOME (path to the Android SDK), but got: ANDROID_HOME=%s", v)
		}
		if v, ok := os.LookupEnv("ANDROID_NDK_HOME"); v == "" || !ok {
			log.Fatalf("[gobind_wrapper.go] Requires ANDROID_NDK_HOME, but got: ANDROID_NDK_HOME=%s", v)
		}
		return
	}
	if *target == "ios" {
		return
	}

	// panic("Flag `target`: expected either android or ios.")
}

func main() {
	flag.Parse()
	log.Printf("[gobind_wrapper.go] Parsd flags flags.Args() = %v", flag.Args())

	if wd, err := os.Getwd(); err != nil {
		panic(err)
	} else {
		log.Printf("[gobind_wrapper.go] Current working dir: %v", wd)
	}
	checkPrecondition()

	if err := run(*gomobile, "init", "-v"); err != nil {
		panic(err)
	}
	if err := run(*gomobile, flag.Args()...); err != nil {
		panic(err)
	}
}
