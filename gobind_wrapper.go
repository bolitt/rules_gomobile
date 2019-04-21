package main

import (
	"flag"
	"os"
	"os/exec"
	"path/filepath"
)

var (
	gobind = flag.String("gobind", "", "")
	zipper = flag.String("zipper", "", "")
	outdir = flag.String("outdir", "", "")
	outjar = flag.String("outjar", "", "")
)

func run(command string, args ...string) error {
	cmd := exec.Command(command, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func makeArchive(archive, dir string) error {
	args := []string{"c", archive}
	filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if info.IsDir() {
			return nil
		}
		args = append(args, path[len(dir)+1:]+"="+path)
		return nil
	})
	return run(*zipper, args...)
}

func main() {
	flag.Parse()
	if err := run(*gobind, flag.Args()...); err != nil {
		panic(err)
	}
	if err := makeArchive(*outjar, *outdir+"/java"); err != nil {
		panic(err)
	}
}
