FROM bearstech/debian-dev:stretch

ENV GOLANG_VERSION=1.12.5
ENV PATH=/opt/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV GOPATH=/go
ENV GOROOT=/opt/go

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /opt
RUN set -eux \
    &&  curl -qL https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-amd64.tar.gz | tar -xz \
    &&  mkdir /go \
    &&  chmod 777 /go

SHELL ["/bin/sh", "-c"]

WORKDIR /go

ARG GIT_VERSION
LABEL com.bearstech.source.golang=https://github.com/factorysh/docker-golang/commit/${GIT_VERSION}

ARG GIT_DATE
LABEL com.bearstech.date.golang=${GIT_DATE}
# Use this image using :
# - go build [YOUR_DIR]
# - make ...
