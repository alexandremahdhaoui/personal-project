#!/bin/sh

set -xe

# DISCLAIMER: This script is intended to run inside an init-container, therefore cleanup's are skipped
# test: k run fedora --image fedora:latest --command -- sleep 3600 && k exec -it fedora -- bash

INPUT_FILE="${1}"
OUTPUT_FILE="${2}"

# Prerequisites
dnf install -y butane

butane --pretty --strict "${INPUT_FILE}" | tee "${OUTPUT_FILE}"
