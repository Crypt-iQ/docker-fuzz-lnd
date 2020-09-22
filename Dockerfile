FROM golang:1.14.9-alpine as builder

ARG checkout="master"

RUN apk add --no-cache --update alpine-sdk \
	git \
	make \
	gcc \
	&& git clone https://github.com/lightningnetwork/lnd /go/src/github.com/lightningnetwork/lnd \
	&& cd /go/src/github.com/lightningnetwork/lnd \
	&& git checkout $checkout \
	&& make \
	&& make install tags="signrpc walletrpc chainrpc invoicesrpc" \
	&& go get -u github.com/dvyukov/go-fuzz/go-fuzz github.com/dvyukov/go-fuzz/go-fuzz-build \
	&& cd fuzz/lnwire \
	&& find * -maxdepth 1 -regex '[A-Za-z0-9\-_.]'* -not -name fuzz_utils.go | sed 's/\.go$//1' | xargs -I % sh -c 'echo "building"; go-fuzz-build -func Fuzz_% -o lnwire-%-fuzz.zip github.com/lightningnetwork/lnd/fuzz/lnwire'

