#!/bin/bash
set -e

ctr=$(buildah from ubuntu:22.04)

buildah run $ctr apt-get update
buildah run $ctr apt-get install -y curl

buildah config --author "Dein Name" --label version=1.0 $ctr
buildah commit $ctr ubuntu-curl:1.0

podman run ubuntu-curl:1.0 curl --version
