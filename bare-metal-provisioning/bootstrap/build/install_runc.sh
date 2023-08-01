#!/bin/bash

set -xe

# Preparing workdir
WORKDIR="/tmp"
cd "${WORKDIR}" || exit 1

# Prepare GOCACHE
export GOCACHE="/tmp/gocache"
mkdir -p "${GOCACHE}"

# Env
REPO="https://github.com/opencontainers/runc"
REPO_DIR="$(basename "${REPO}" .git)"
# shellcheck disable=SC2115
rm -rf "${WORKDIR}/${REPO_DIR}"

# Pre-install
dnf install -y git protobuf-compiler golang libseccomp libseccomp-devel

# Install

git clone "${REPO}"
cd "${REPO_DIR}" || exit 1
make
make install

# Post-install
dnf remove -y protobuf-compiler golang

# Cleanup
cd "${WORKDIR}" || exit 1
rm -rf "./${REPO_DIR}"
rm -rf "${GOCACHE}"
