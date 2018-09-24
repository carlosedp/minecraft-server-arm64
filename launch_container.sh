#!/bin/bash

mkdir ~/mc-data && chmod 777 ~/mc-data
docker run -d -it \
    -v ~/mc-data:/data \
    -p 25565:25565 \
    -p 25575:25575 \
    -e VERSION=1.12.2 \
    -e TYPE=FORGE \
    -e FORGEVERSION=14.23.4.2739 \
    -e MEMORY=3G \
    -e ALLOW_FLIGHT=TRUE \
    --name mc \
    carlosedp/minecraft-server:arm64
