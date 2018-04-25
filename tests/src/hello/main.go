package main

import (
	"fmt"
	"stringutil"
)

func main() {
	msg := "Hello world !"

	fmt.Println(msg)
	fmt.Println(stringutil.Reverse(msg))
	fmt.Println(stringutil.Reverse(stringutil.Reverse(msg)))
}
