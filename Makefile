all: golang glide dep

golang:
	docker build -t bearstech/golang-dev:stretch -f Dockerfile .
	docker tag bearstech/golang-dev:stretch bearstech/golang-dev:9
	docker tag bearstech/golang-dev:stretch bearstech/golang-dev:latest

glide:
	docker build -t bearstech/golang-glide:stretch -f Dockerfile.glide .
	docker tag bearstech/golang-glide:stretch bearstech/golang-glide:9
	docker tag bearstech/golang-glide:stretch bearstech/golang-glide:latest

dep:
	docker build -t bearstech/golang-dep:stretch -f Dockerfile.dep .
	docker tag bearstech/golang-dep:stretch bearstech/golang-dep:9
	docker tag bearstech/golang-dep:stretch bearstech/golang-dep:latest

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
