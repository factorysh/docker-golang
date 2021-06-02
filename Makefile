
include Makefile.lint
include Makefile.build_args

GOSS_VERSION := 0.3.13
NODE_VERSION = $(shell curl -qs https://deb.nodesource.com/node_16.x/dists/$(DEBIAN_VERSION)/main/binary-amd64/Packages | grep -m 1 Version: | cut -d " " -f 2 -)
DEBIAN_VERSION=bullseye

all: pull build

pull:
	docker pull bearstech/debian-dev:$(DEBIAN_VERSION)

# protobuild is broken
#build: golang glide protobuild dep node
build: golang glide dep node

golang:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg DEBIAN_VERSION="${DEBIAN_VERSION}" \
		-t bearstech/golang-dev:$(DEBIAN_VERSION) \
		-f Dockerfile \
		.
	docker tag bearstech/golang-dev:$(DEBIAN_VERSION) bearstech/golang-dev:latest

glide:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		-t bearstech/golang-glide:$(DEBIAN_VERSION) \
		-f Dockerfile.glide \
		.
	docker tag bearstech/golang-glide:$(DEBIAN_VERSION) bearstech/golang-glide:latest

protobuild:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		-t bearstech/golang-protobuild:$(DEBIAN_VERSION) \
		-f Dockerfile.protobuild \
		.
	docker tag bearstech/golang-protobuild:$(DEBIAN_VERSION) bearstech/golang-protobuild:latest

dep:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		-t bearstech/golang-dep:$(DEBIAN_VERSION) \
		-f Dockerfile.dep \
		.
	docker tag bearstech/golang-dep:$(DEBIAN_VERSION) bearstech/golang-dep:latest

node:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		-t bearstech/golang-node:latest \
		--build-arg NODE_VERSION=${NODE_VERSION} \
		--build-arg NODE_MAJOR_VERSION=10 \
		-f Dockerfile.node \
		.

push:
	docker push bearstech/golang-dev:$(DEBIAN_VERSION)
	docker push bearstech/golang-dev:latest
	docker push bearstech/golang-glide:$(DEBIAN_VERSION)
	docker push bearstech/golang-glide:latest
	docker push bearstech/golang-dep:$(DEBIAN_VERSION)
	docker push bearstech/golang-dep:latest
	docker push bearstech/golang-node:latest

remove_image:
	docker rmi bearstech/golang-dev:$(DEBIAN_VERSION)
	docker rmi bearstech/golang-dev:latest
	docker rmi bearstech/golang-glide:$(DEBIAN_VERSION)
	docker rmi bearstech/golang-glide:latest
	docker rmi bearstech/golang-dep:$(DEBIAN_VERSION)
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
			IMG_CONTAINER="bearstech/golang-dev:$(DEBIAN_VERSION)" \
			CMD_CONTAINER="goss -g go-dev.yaml --vars vars/go_standard.yaml validate --max-concurrent 4 --format documentation"

test-dep: bin/goss
	rm -rf tests_golang/src/pkg_errors/Gopkg.lock tests_golang/src/pkg_errors/Gopkg.toml tests_golang/src/pkg_errors/_vendor-*
	@make -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-dep:$(DEBIAN_VERSION)" \
			CMD_CONTAINER="goss -g go-dep.yaml --vars vars/go_standard.yaml validate --max-concurrent 4 --format documentation"
	rm -rf tests_golang/src/pkg_errors/Gopkg.lock tests_golang/src/pkg_errors/Gopkg.toml tests_golang/src/pkg_errors/_vendor-*

test-glide: bin/goss
	rm -rf tests_golang/src/pkg_errors/glide.lock tests_golang/src/pkg_errors/glide.yaml tests_golang/src/pkg_errors/vendor/ tests_golang/.glide/
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-glide:$(DEBIAN_VERSION)" \
			CMD_CONTAINER="goss -g go-glide.yaml --vars vars/go_standard.yaml validate --max-concurrent 4 --format documentation"
	rm -rf tests_golang/src/pkg_errors/glide.lock tests_golang/src/pkg_errors/glide.yaml tests_golang/src/pkg_errors/vendor/ tests_golang/.glide/

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

tests: test-golang test-glide test-dep test-node
