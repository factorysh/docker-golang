all: glide

glide:
	docker build -t bearstech/golang-glide:stretch -f Dockerfile.glide .
	docker tag bearstech/golang-glide:stretch bearstech/golang-glide:9
	docker tag bearstech/golang-glide:stretch bearstech/golang-glide:latest

push:
	docker push bearstech/golang-glide:stretch
	docker push bearstech/golang-glide:9
	docker push bearstech/golang-glide:latest
