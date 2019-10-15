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


# Use this image using :
# - go build [YOUR_DIR]
# - make ...

# generated labels

ARG GIT_VERSION
ARG GIT_DATE
ARG BUILD_DATE

LABEL com.bearstech.image.revision_date=${GIT_DATE}

LABEL org.opencontainers.image.authors=Bearstech

LABEL org.opencontainers.image.revision=${GIT_VERSION}
LABEL org.opencontainers.image.created=${BUILD_DATE}

LABEL org.opencontainers.image.url=https://github.com/factorysh/docker-golang
LABEL org.opencontainers.image.source=https://github.com/factorysh/docker-golang/blob/${GIT_VERSION}/Dockerfile
