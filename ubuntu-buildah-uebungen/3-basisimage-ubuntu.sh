#!/bin/bash
set -e

ctr=$(buildah from ubuntu:22.04)

buildah run $ctr apt-get update
buildah run $ctr apt-get install -y iputils-ping

buildah config --entrypoint '["ping", "8.8.8.8"]' $ctr
buildah commit $ctr ping-ubuntu:latest

podman run ping-ubuntu:latest
