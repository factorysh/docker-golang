
include Makefile.lint
include Makefile.build_args

GOSS_VERSION := 0.3.16
NODE_MAJOR_VERSION = 16
NODE_VERSION = $(shell curl -qs https://deb.nodesource.com/node_$(NODE_MAJOR_VERSION).x/dists/$(DEBIAN_VERSION)/main/binary-amd64/Packages | grep -m 1 Version: | cut -d " " -f 2 -)
DEBIAN_VERSION=bullseye

all: pull build

pull:
	docker pull bearstech/debian-dev:$(DEBIAN_VERSION)

# protobuild is broken
build: golang node

golang:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg DEBIAN_VERSION="${DEBIAN_VERSION}" \
		-t bearstech/golang-dev:$(DEBIAN_VERSION) \
		-f Dockerfile \
		.
	docker tag bearstech/golang-dev:$(DEBIAN_VERSION) bearstech/golang-dev:latest

protobuild:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg DEBIAN_VERSION="${DEBIAN_VERSION}" \
		-t bearstech/golang-protobuild:$(DEBIAN_VERSION) \
		-f Dockerfile.protobuild \
		.
	docker tag bearstech/golang-protobuild:$(DEBIAN_VERSION) bearstech/golang-protobuild:latest

node:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		-t bearstech/golang-node:latest \
		--build-arg DEBIAN_VERSION="${DEBIAN_VERSION}" \
		--build-arg NODE_VERSION=${NODE_VERSION} \
		--build-arg NODE_MAJOR_VERSION=${NODE_MAJOR_VERSION} \
		-f Dockerfile.node \
		.

push:
	docker push bearstech/golang-dev:$(DEBIAN_VERSION)
	docker push bearstech/golang-dev:latest
	docker push bearstech/golang-node:latest

remove_image:
	docker rmi bearstech/golang-dev:$(DEBIAN_VERSION)
	docker rmi bearstech/golang-dev:latest
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
		-v `pwd`/tests_golang:/go/app \
		-v `pwd`/.cache:/.cache \
		-w /go/app \
		-u `id -u` \
		${IMG_CONTAINER} ${CMD_CONTAINER}

test-golang: bin/goss
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-dev:$(DEBIAN_VERSION)" \
			CMD_CONTAINER="goss -g go-dev.yaml --vars vars/go_standard.yaml validate --max-concurrent 4 --format documentation"

test-protobuild: bin/goss
	rm -rf tests_golang/src/protoc_test/doc.pb.go
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-protobuild:$(DEBIAN_VERSION)" \
			CMD_CONTAINER="goss -g go-protobuild.yaml --vars vars/go_protobuild_node.yaml validate --max-concurrent 4 --format documentation"
	rm -rf tests_golang/src/protoc_test/doc.pb.go

test-node: bin/goss
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-node:latest" \
			CMD_CONTAINER="goss -g go-dev.yaml --vars vars/go_protobuild_node.yaml validate --max-concurrent 4 --format documentation"

down:

tests: test-golang test-node
