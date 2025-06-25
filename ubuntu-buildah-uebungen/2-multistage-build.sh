#!/bin/bash
set -e

buildah bud -t go-app-ubuntu:latest -f 2-multistage-build-containerfile .
podman run go-app-ubuntu:latest
