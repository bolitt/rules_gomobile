package helloworld

import (
	"fmt"

	"github.com/bolitt/rules_gomobile/examples/helloworld/util"
)

//export Hello
func Hello(name string) string {
	s := fmt.Sprintf("Hello %v [from %v]", name, util.GlobalName)
	print(s)
	return s
}
