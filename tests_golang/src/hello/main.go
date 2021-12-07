package main

import (
	"fmt"
	"example.com/example/stringutil"
)

func main() {
	msg := "Hello world !"

	fmt.Println(msg)
	fmt.Println(stringutil.Reverse(msg))
	fmt.Println(stringutil.Reverse(stringutil.Reverse(msg)))
}
