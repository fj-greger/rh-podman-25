#!/bin/bash
set -e

# Baue das Image mit Buildah
buildah bud -t my-go-app -f Containerfile .

# Starte es zum Test
podman run --rm my-go-app
