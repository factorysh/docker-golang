GOSS_VERSION := 0.3.5

all: pull build

pull:
	docker pull bearstech/debian-dev:stretch

build: golang glide protobuild dep node

golang:
	docker build -t bearstech/golang-dev:stretch -f Dockerfile .
	docker tag bearstech/golang-dev:stretch bearstech/golang-dev:9
	docker tag bearstech/golang-dev:stretch bearstech/golang-dev:latest

glide:
	docker build -t bearstech/golang-glide:stretch -f Dockerfile.glide .
	docker tag bearstech/golang-glide:stretch bearstech/golang-glide:9
	docker tag bearstech/golang-glide:stretch bearstech/golang-glide:latest

protobuild:
	docker build -t bearstech/golang-protobuild:stretch -f Dockerfile.protobuild .
	docker tag bearstech/golang-protobuild:stretch bearstech/golang-protobuild:9
	docker tag bearstech/golang-protobuild:stretch bearstech/golang-protobuild:latest

dep:
	docker build -t bearstech/golang-dep:stretch -f Dockerfile.dep .
	docker tag bearstech/golang-dep:stretch bearstech/golang-dep:9
	docker tag bearstech/golang-dep:stretch bearstech/golang-dep:latest

node:
	docker build -t bearstech/golang-node:latest -f Dockerfile.node .

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

bin/goss:
	mkdir -p bin
	curl -o bin/goss -L https://github.com/aelsabbahy/goss/releases/download/v${GOSS_VERSION}/goss-linux-amd64
	chmod +x bin/goss

NAME_CONTAINER := ""
CMD_CONTAINER := ""
IMG_CONTAINER := ""

test-deployed:
	@test "${NAME_CONTAINER}" || (echo "you cannot call this rule..." && exit 1)
	@test "${CMD_CONTAINER}" || (echo "you cannot call this rule..." && exit 1)
	@test "${IMG_CONTAINER}" || (echo "you cannot call this rule..." && exit 1)
	@docker stop ${NAME_CONTAINER} > /dev/null 2>&1 && docker rm ${NAME_CONTAINER} > /dev/null 2>&1 && true
	@docker run -d -t --name ${NAME_CONTAINER} ${IMG_CONTAINER} > /dev/null
	@docker cp tests/. ${NAME_CONTAINER}:/go
	@docker cp bin/goss ${NAME_CONTAINER}:/usr/local/bin/goss
	@docker exec -t -w /go ${NAME_CONTAINER} ${CMD_CONTAINER}
	@docker stop ${NAME_CONTAINER} > /dev/null
	@docker rm ${NAME_CONTAINER} > /dev/null

test-golang: bin/goss
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-dev:9" \
			CMD_CONTAINER="goss -g go-dev.yaml --vars vars/go_standard.yaml validate --max-concurrent 4 --format documentation"

test-glide: bin/goss
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-glide:9" \
			CMD_CONTAINER="goss -g go-dev.yaml --vars vars/go_standard.yaml validate --max-concurrent 4 --format documentation"

test-dep: bin/goss
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-dep:9" \
			CMD_CONTAINER="goss -g go-dev.yaml --vars vars/go_standard.yaml validate --max-concurrent 4 --format documentation"

test-protobuild: bin/goss
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-protobuild:9" \
			CMD_CONTAINER="goss -g go-dev.yaml --vars vars/go_protobuild_node.yaml validate --max-concurrent 4 --format documentation"

test-node: bin/goss
	@make -s -C . test-deployed \
			NAME_CONTAINER="$@" \
			IMG_CONTAINER="bearstech/golang-node:latest" \
			CMD_CONTAINER="goss -g go-dev.yaml --vars vars/go_protobuild_node.yaml validate --max-concurrent 4 --format documentation"

tests: test-golang test-glide test-dep test-protobuild test-node