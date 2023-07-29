#!/bin/bash

# Preparing workdir
WORKDIR="/tmp"
cd "${WORKDIR}" || exit 1

# Env
REPO="https://github.com/opencontainers/runc"
REPO_DIR="$(basename "${REPO}" .git)"

# Pre-install
dnf install -y protobuf-compiler golang

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