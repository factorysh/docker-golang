GOSS_VERSION := 0.3.5
NODE10_VERSION = $(shell curl -qs https://deb.nodesource.com/node_10.x/dists/stretch/main/binary-amd64/Packages | grep -m 1 Version: | cut -d " " -f 2 -)
GIT_VERSION := $(shell git rev-parse HEAD)
GIT_DATE := $(shell git show -s --format=%ci HEAD)

all: pull build

pull:
	docker pull bearstech/debian-dev:stretch

build: golang glide protobuild dep node

golang:
	docker build \
		-t bearstech/golang-dev:stretch \
		--build-arg GIT_VERSION=${GIT_VERSION} \
		--build-arg GIT_DATE="${GIT_DATE}" \
		-f Dockerfile \
		.
	docker tag bearstech/golang-dev:stretch bearstech/golang-dev:9
	docker tag bearstech/golang-dev:stretch bearstech/golang-dev:latest

glide:
	docker build \
		-t bearstech/golang-glide:stretch \
		--build-arg GIT_VERSION=${GIT_VERSION} \
		--build-arg GIT_DATE="${GIT_DATE}" \
		-f Dockerfile.glide \
		.
	docker tag bearstech/golang-glide:stretch bearstech/golang-glide:9
	docker tag bearstech/golang-glide:stretch bearstech/golang-glide:latest

protobuild:
	docker build \
		-t bearstech/golang-protobuild:stretch \
		--build-arg GIT_VERSION=${GIT_VERSION} \
		--build-arg GIT_DATE="${GIT_DATE}" \
		-f Dockerfile.protobuild \
		.
	docker tag bearstech/golang-protobuild:stretch bearstech/golang-protobuild:9
	docker tag bearstech/golang-protobuild:stretch bearstech/golang-protobuild:latest

dep:
	docker build \
		-t bearstech/golang-dep:stretch \
		--build-arg GIT_VERSION=${GIT_VERSION} \
		--build-arg GIT_DATE="${GIT_DATE}" \
		-f Dockerfile.dep \
		.
	docker tag bearstech/golang-dep:stretch bearstech/golang-dep:9
	docker tag bearstech/golang-dep:stretch bearstech/golang-dep:latest

node:
	docker build \
		-t bearstech/golang-node:latest \
		--build-arg GIT_VERSION=${GIT_VERSION} \
		--build-arg GIT_DATE="${GIT_DATE}" \
		--build-arg NODE_VERSION=${NODE10_VERSION} \
		--build-arg NODE_MAJOR_VERSION=10 \
		-f Dockerfile.node \
		.

push:
	docker push bearstech/golang-dev:stretch
	docker push bearstech/golang-dev:9
	docker push bearstech/golang-dev:latest
	docker push bearstech/golang-glide:stretch
	docker push bearstech/golang-glide:9
	docker push bearstech/golang-glide:latest
	docker push bearstech/golang-dep:stretch
	docker push bearstech/golang-dep:9
	docker push bearstech/golang-dep:latest
	docker push bearstech/golang-node:latest

remove_image:
	docker rmi bearstech/golang-dev:stretch
	docker rmi bearstech/golang-dev:9
	docker rmi bearstech/golang-dev:latest
	docker rmi bearstech/golang-glide:stretch
	docker rmi bearstech/golang-glide:9
	docker rmi bearstech/golang-glide:latest
	docker rmi bearstech/golang-dep:stretch
	docker rmi bearstech/golang-dep:9
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
			IMG_CONTAINER="bearstech/golang-dev:9" \
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
			IMG_CONTAINER="bearstech/golang-glide:9" \
			CMD_CONTAINER="goss -g go-glide.yaml --vars vars/go_standard.yaml validate --max-concurrent 4 --format documentation"
	rm -rf tests_golang/src/pkg_errors/glide.lock tests_golang/src/pkg_errors/glide.yaml tests_golang/src/pkg_errors/vendor/ tests_golang/.glide/

test-protobuild: bin/goss
	rm -rf tests_golang/src/protoc_test/doc.pb.go
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-protobuild:9" \
			CMD_CONTAINER="goss -g go-protobuild.yaml --vars vars/go_protobuild_node.yaml validate --max-concurrent 4 --format documentation"
	rm -rf tests_golang/src/protoc_test/doc.pb.go

test-node: bin/goss
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-node:latest" \
			CMD_CONTAINER="goss -g go-dev.yaml --vars vars/go_protobuild_node.yaml validate --max-concurrent 4 --format documentation"

down:

tests: test-golang test-glide test-dep test-protobuild test-node
