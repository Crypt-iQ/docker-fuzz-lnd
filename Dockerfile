FROM golang:1.14.9-alpine as builder

ARG checkout="master"

RUN apk add --no-cache --update alpine-sdk \
	git \
	make \
	gcc \
	&& git clone https://github.com/lightningnetwork/lnd /go/src/github.com/lightningnetwork/lnd \
	&& git clone https://github.com/Crypt-iQ/lnd_fuzz_seeds /go/src/github.com/Crypt-iQ/lnd_fuzz_seeds \
	&& cd /go/src/github.com/lightningnetwork/lnd \
	&& git fetch origin pull/4641/head:4641_fuzzing_fixups \
	&& git checkout 4641_fuzzing_fixups \
	&& make \
	&& make install tags="signrpc walletrpc chainrpc invoicesrpc" \
	&& go get -u github.com/dvyukov/go-fuzz/go-fuzz github.com/dvyukov/go-fuzz/go-fuzz-build \
	&& cd fuzz/lnwire \
	&& find * -maxdepth 1 -regex '[A-Za-z0-9\-_.]'* -not -name fuzz_utils.go | sed 's/\.go$//1' | xargs -I % sh -c 'echo "building %"; go-fuzz-build -func Fuzz_% -o lnwire-%-fuzz.zip github.com/lightningnetwork/lnd/fuzz/lnwire; echo "running %"; timeout 10s go-fuzz -bin=lnwire-%-fuzz.zip -workdir=/go/src/github.com/Crypt-iQ/lnd_fuzz_seeds/lnwire/% || true' \
	&& cd ../brontide \
	&& find * -maxdepth 1 -regex '[A-Za-z0-9\-_.]'* -not -name fuzz_utils.go | sed 's/\.go$//1' | xargs -I % sh -c 'echo "building %"; go-fuzz-build -func Fuzz_% -o brontide-%-fuzz.zip github.com/lightningnetwork/lnd/fuzz/brontide; echo "running %"; timeout 10s go-fuzz -bin=brontide-%-fuzz.zip -workdir=/go/src/github.com/Crypt-iQ/lnd_fuzz_seeds/brontide/% || true' \
	&& cd ../wtwire \
	&& find * -maxdepth 1 -regex '[A-Za-z0-9\-_.]'* -not -name fuzz_utils.go | sed 's/\.go$//1' | xargs -I % sh -c 'echo "building %"; go-fuzz-build -func Fuzz_% -o wtwire-%-fuzz.zip github.com/lightningnetwork/lnd/fuzz/wtwire; echo "running %"; timeout 10s go-fuzz -bin=wtwire-%-fuzz.zip -workdir=/go/src/github.com/Crypt-iQ/lnd_fuzz_seeds/wtwire/% || true' \
	&& cd ../tlv \
	&& find * -maxdepth 1 -regex '[A-Za-z0-9\-_.]'* -not -name fuzz_utils.go | sed 's/\.go$//1' | xargs -I % sh -c 'echo "building %"; go-fuzz-build -func Fuzz_% -o tlv-%-fuzz.zip github.com/lightningnetwork/lnd/fuzz/tlv; echo "running %"; timeout 10s go-fuzz -bin=tlv-%-fuzz.zip -workdir=/go/src/github.com/Crypt-iQ/lnd_fuzz_seeds/tlv/% || true' \
	&& echo "now ending the fuzzing tests" 

 
