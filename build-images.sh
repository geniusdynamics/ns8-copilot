#!/bin/bash

#
# Copyright (C) 2023 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Terminate on error
set -e

# Prepare variables for later use
images=()
# The image will be pushed to GitHub container registry
repobase="${REPOBASE:-ghcr.io/geniusdynamics}"
# Configure the image name. The ghcr.io/geniusdynamics/copilot package
# belongs to an older repository and refuses the pushes of this one
# (denied: permission_denied: write_package).
reponame="socfortress-copilot"
# Node.js 25+ no longer ships Corepack, install it from npm
# renovate: datasource=npm packageName=corepack
corepack_version=0.36.0

# Images of the upstream docker-compose.yml, https://github.com/socfortress/CoPilot
# renovate: datasource=docker packageName=docker.io/library/mysql
MYSQL_VERSION=8.0.46-debian
# renovate: datasource=docker packageName=ghcr.io/socfortress/minio
MINIO_VERSION=RELEASE.2024-09-13T20-26-02Z
# SOCFortress publishes the CoPilot images with the "latest" tag only, no
# version tag: pin the digest of the image index. Renovate updates the digest,
# and a node pulls the image again on update only when the digest changes.
copilot_backend_image="ghcr.io/socfortress/copilot-backend:latest@sha256:eb95ceb1d68e866ea902f90f27452ebdd3ec76e365dbf659e77ac5003b387328"
copilot_frontend_image="ghcr.io/socfortress/copilot-frontend:latest@sha256:bc9dece32b450a2f1f71e97a16a526cfeb452306f8c664ad7e1801f38dfbe759"
copilot_nuclei_image="ghcr.io/socfortress/copilot-nuclei-module:latest@sha256:9014788fa96786ac5b59faed497db0d62679993791a68600d1e3df0d4bb133e1"

# Create a new empty container image
container=$(buildah from scratch)

# Reuse existing nodebuilder-copilot container, to speed up builds
if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-copilot; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-copilot -v "${PWD}:/usr/src:Z" docker.io/library/node:26.13.0-slim
    buildah run nodebuilder-copilot sh -c "npm install -g corepack@${corepack_version} && corepack enable"
fi

echo "Build static UI files with node..."
buildah run \
    --workingdir=/usr/src/ui \
    --env="NODE_OPTIONS=--openssl-legacy-provider" \
    nodebuilder-copilot \
    sh -c "yarn install && yarn build"

# Add imageroot directory to the container image
buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# One TCP port for Traefik, rootless. The images of the pod come from the
# variables above.
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=traefik@node:routeadm" \
    --label="org.nethserver.tcp-ports-demand=1" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.min-core=3.0.0" \
    --label="org.nethserver.images=docker.io/library/mysql:${MYSQL_VERSION} ghcr.io/socfortress/minio:${MINIO_VERSION} ${copilot_backend_image} ${copilot_frontend_image} ${copilot_nuclei_image}" \
    "${container}"
# Commit the image
buildah commit "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

#
# NOTICE:
#
# It is possible to build and publish multiple images.
#
# 1. create another buildah container
# 2. add things to it and commit it
# 3. append the image url to the images array
#

#
# Setup CI when pushing to Github. 
# Warning! docker::// protocol expects lowercase letters (,,)
if [[ -n "${CI}" ]]; then
    # Set output value for Github Actions
    printf "images=%s\n" "${images[*],,}" >> "${GITHUB_OUTPUT}"
else
    # Just print info for manual push
    printf "Publish the images with:\n\n"
    for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}" ; done
    printf "\n"
fi
