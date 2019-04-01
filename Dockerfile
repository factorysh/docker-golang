FROM bearstech/debian-dev:stretch

ENV GOLANG_VERSION=1.12.1
ENV PATH=/opt/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV GOPATH=/go
ENV GOROOT=/opt/go

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /opt
RUN set -eux \
    &&  curl -qL https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-amd64.tar.gz | tar -xz \
    &&  useradd --home-dir /go --create-home --shell /bin/bash go \
    &&  chmod 777 /go

SHELL ["/bin/sh", "-c"]

USER go
WORKDIR /go

# Use this image using :
# - go build [YOUR_DIR]
# - make ...
