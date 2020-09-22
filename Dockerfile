FROM golang:1.14.9-alpine as builder

ARG checkout="master"

RUN apk add --no-cache --update alpine-sdk \
	git \
	make \
	gcc \
	&& git clone https://github.com/lightningnetwork/lnd /go/src/github.com/lightningnetwork/lnd \
	&& git clone https://github.com/Crypt-iQ/lnd_fuzz_seeds \
	&& cd /go/src/github.com/lightningnetwork/lnd \
	&& git fetch origin pulls/4640/head:4640_fuzzing_fixups \
	&& git checkout 4640_fuzzing_fixups \
	&& make \
	&& make install tags="signrpc walletrpc chainrpc invoicesrpc" \
	&& go get -u github.com/dvyukov/go-fuzz/go-fuzz github.com/dvyukov/go-fuzz/go-fuzz-build \
	&& cd fuzz/lnwire \
	&& find * -maxdepth 1 -regex '[A-Za-z0-9\-_.]'* -not -name fuzz_utils.go | sed 's/\.go$//1' | xargs -I % sh -c 'echo "building"; go-fuzz-build -func Fuzz_% -o lnwire-%-fuzz.zip github.com/lightningnetwork/lnd/fuzz/lnwire' \
	&& cd ../brontide \
	&& find * -maxdepth 1 -regex '[A-Za-z0-9\-_.]'* -not -name fuzz_utils.go | sed 's/\.go$//1' | xargs -I % sh -c 'echo "building"; go-fuzz-build -func Fuzz_% -o brontide-%-fuzz.zip github.com/lightningnetwork/lnd/fuzz/brontide' \
	&& cd ../wtwire \
	&& find * -maxdepth 1 -regex '[A-Za-z0-9\-_.]'* -not -name fuzz_utils.go | sed 's/\.go$//1' | xargs -I % sh -c 'echo "building"; go-fuzz-build -func Fuzz_% -o wtwire-%-fuzz.zip github.com/lightningnetwork/lnd/fuzz/wtwire' \
	&& echo "now running the regression fuzzing tests" \ 
