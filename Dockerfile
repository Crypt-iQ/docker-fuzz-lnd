FROM golang:1.14.9-alpine as builder

ARG checkout="master"

RUN apk add --no-cache --update alpine-sdk \
	git \
	make \
	&& git clone https://github.com/lightningnetwork/lnd /go/src/github.com/lightningnetwork/lnd \
	&& cd /go/src/github.com/lightningnetwork/lnd \
	&& make \
	&& make fuzz-build pkg=zpay32 \
	&& make fuzz-run pkg=zpay32 processes=4 base_workdir=/go/src/github.com/lightningnetwork/lnd \
