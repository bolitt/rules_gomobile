package helloworld

import (
	"fmt"

	"github.com/example/project/examples/helloworld/util"
)

//export Hello
func Hello(name string) string {
	s := fmt.Sprintf("Hello %v [from %v]", name, util.GlobalName)
	print(s)
	return s
}
