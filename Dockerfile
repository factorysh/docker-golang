FROM bearstech/debian-dev:stretch

ENV GOLANG_VERSION=1.9.1
RUN cd /opt && curl -qL https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-amd64.tar.gz | tar -xz

ENV PATH=/opt/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN useradd --home-dir /go --create-home --shell /bin/bash go

RUN chmod 777 /go

WORKDIR /go
USER go

ENV GOPATH=/go
ENV GOROOT=/opt/go
