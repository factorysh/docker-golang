
include Makefile.lint
include Makefile.build_args

GOSS_VERSION := 0.3.13
NODE_VERSION = $(shell curl -qs https://deb.nodesource.com/node_14.x/dists/buster/main/binary-amd64/Packages | grep -m 1 Version: | cut -d " " -f 2 -)

all: pull build

pull:
	docker pull bearstech/debian-dev:buster

build: golang glide protobuild dep node

golang:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		-t bearstech/golang-dev:buster \
		-f Dockerfile \
		.
	docker tag bearstech/golang-dev:buster bearstech/golang-dev:10
	docker tag bearstech/golang-dev:buster bearstech/golang-dev:latest

glide:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		-t bearstech/golang-glide:buster \
		-f Dockerfile.glide \
		.
	docker tag bearstech/golang-glide:buster bearstech/golang-glide:10
	docker tag bearstech/golang-glide:buster bearstech/golang-glide:latest

protobuild:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		-t bearstech/golang-protobuild:buster \
		-f Dockerfile.protobuild \
		.
	docker tag bearstech/golang-protobuild:buster bearstech/golang-protobuild:10
	docker tag bearstech/golang-protobuild:buster bearstech/golang-protobuild:latest

dep:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		-t bearstech/golang-dep:buster \
		-f Dockerfile.dep \
		.
	docker tag bearstech/golang-dep:buster bearstech/golang-dep:10
	docker tag bearstech/golang-dep:buster bearstech/golang-dep:latest

node:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		-t bearstech/golang-node:latest \
		--build-arg NODE_VERSION=${NODE_VERSION} \
		--build-arg NODE_MAJOR_VERSION=10 \
		-f Dockerfile.node \
		.

push:
	docker push bearstech/golang-dev:buster
	docker push bearstech/golang-dev:10
	docker push bearstech/golang-dev:latest
	docker push bearstech/golang-glide:buster
	docker push bearstech/golang-glide:10
	docker push bearstech/golang-glide:latest
	docker push bearstech/golang-dep:buster
	docker push bearstech/golang-dep:10
	docker push bearstech/golang-dep:latest
	docker push bearstech/golang-node:latest

remove_image:
	docker rmi bearstech/golang-dev:buster
	docker rmi bearstech/golang-dev:10
	docker rmi bearstech/golang-dev:latest
	docker rmi bearstech/golang-glide:buster
	docker rmi bearstech/golang-glide:10
	docker rmi bearstech/golang-glide:latest
	docker rmi bearstech/golang-dep:buster
	docker rmi bearstech/golang-dep:10
	docker rmi bearstech/golang-dep:latest
	docker rmi bearstech/golang-node:latest

bin/goss:
	mkdir -p bin
	curl -o bin/goss -L https://github.com/aelsabbahy/goss/releases/download/v${GOSS_VERSION}/goss-linux-amd64
	chmod +x bin/goss

NAME_CONTAINER := ""
CMD_CONTAINER := ""
IMG_CONTAINER := ""

.cache:
	mkdir -p .cache

test-deployed: .cache
	@test "${NAME_CONTAINER}" || (echo "you cannot call this rule..." && exit 1)
	@test "${CMD_CONTAINER}" || (echo "you cannot call this rule..." && exit 1)
	@test "${IMG_CONTAINER}" || (echo "you cannot call this rule..." && exit 1)
	docker run --rm -t \
		-v `pwd`/bin/goss:/usr/local/bin/goss \
		-v `pwd`/tests_golang:/go \
		-v `pwd`/.cache:/.cache \
		-w /go \
		-u `id -u` \
		${IMG_CONTAINER} ${CMD_CONTAINER}

test-golang: bin/goss
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-dev:10" \
			CMD_CONTAINER="goss -g go-dev.yaml --vars vars/go_standard.yaml validate --max-concurrent 4 --format documentation"

test-dep: bin/goss
	rm -rf tests_golang/src/pkg_errors/Gopkg.lock tests_golang/src/pkg_errors/Gopkg.toml tests_golang/src/pkg_errors/_vendor-*
	@make -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-dep:9" \
			CMD_CONTAINER="goss -g go-dep.yaml --vars vars/go_standard.yaml validate --max-concurrent 4 --format documentation"
	rm -rf tests_golang/src/pkg_errors/Gopkg.lock tests_golang/src/pkg_errors/Gopkg.toml tests_golang/src/pkg_errors/_vendor-*

test-glide: bin/goss
	rm -rf tests_golang/src/pkg_errors/glide.lock tests_golang/src/pkg_errors/glide.yaml tests_golang/src/pkg_errors/vendor/ tests_golang/.glide/
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-glide:10" \
			CMD_CONTAINER="goss -g go-glide.yaml --vars vars/go_standard.yaml validate --max-concurrent 4 --format documentation"
	rm -rf tests_golang/src/pkg_errors/glide.lock tests_golang/src/pkg_errors/glide.yaml tests_golang/src/pkg_errors/vendor/ tests_golang/.glide/

test-protobuild: bin/goss
	rm -rf tests_golang/src/protoc_test/doc.pb.go
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-protobuild:10" \
			CMD_CONTAINER="goss -g go-protobuild.yaml --vars vars/go_protobuild_node.yaml validate --max-concurrent 4 --format documentation"
	rm -rf tests_golang/src/protoc_test/doc.pb.go

test-node: bin/goss
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-node:latest" \
			CMD_CONTAINER="goss -g go-dev.yaml --vars vars/go_protobuild_node.yaml validate --max-concurrent 4 --format documentation"

down:

tests: test-golang test-glide test-dep test-protobuild test-node
