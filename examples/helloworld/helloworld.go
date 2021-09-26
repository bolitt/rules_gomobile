package helloworld

import (
	"fmt"
)

//export Hello
func Hello(name string) {
	fmt.Println("Hello", name)
}
