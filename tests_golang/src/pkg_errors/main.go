package main

import (
	"fmt"
	"github.com/pkg/errors"
)

func main() {
  err := errors.New("error")
	fmt.Printf("%+v\n", err)
}
