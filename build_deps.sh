#!/bin/bash

pushd deps/restify
git pull
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -a -ldflags '-extldflags "-static"' .
mv restify ../../restify-arm64
popd
pushd deps/rcon-cli
git pull
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -a -ldflags '-extldflags "-static"' .
mv rcon-cli ../../rcon-cli-arm64
popd
pushd deps/mc-server-runner
git pull
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -a -ldflags '-extldflags "-static"' .
mv server ../../server-arm64
popd
pushd deps/su-exec
git pull
make
mv su-exec ../../su-exec-arm64
popd
