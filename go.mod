// Add require in `go.sum` below, and run:
//   bazel run :gazelle -- update-repos -from_file=go.mod -to_macro=repositories.bzl%go_repositories
// It will update `repositories.bzl`

module github.com/bolitt/rules_gomobile

go 1.17

require (
	golang.org/x/mobile v0.0.0-20210924032853-1c027f395ef7
	golang.org/x/sys v0.0.0-20210925032602-92d5a993a665
	golang.org/x/tools v0.1.6
	golang.org/x/xerrors v0.0.0-20200804184101-5ec99f83aff1
)
