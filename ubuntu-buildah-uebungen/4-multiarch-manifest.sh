#!/bin/bash
set -e

buildah bud --arch amd64 -t ubuntu-app:amd64 -f 4-multiarch-containerfile .
buildah bud --arch arm64 -t ubuntu-app:arm64 -f 4-multiarch-containerfile .

buildah manifest create ubuntu-app:multi
buildah manifest add ubuntu-app:multi containers-storage:ubuntu-app:amd64
buildah manifest add ubuntu-app:multi containers-storage:ubuntu-app:arm64

# Optional:
# buildah manifest push ubuntu-app:multi docker://your-registry/ubuntu-app:multi
