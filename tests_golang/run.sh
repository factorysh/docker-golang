#! /usr/bin/env bash

set -e

cd src && go mod init example.com/example || true && go mod tidy || true && go run hello/main.go

rm -rf ./pkg