#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

DEBUG=${DEBUG:=0}
[[ $DEBUG -eq 1 ]] && set -o xtrace

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

pushd "$DIR/../docker"
for image in */; do
  image="${image%/}"
  pushd "$image"
  version=$(sed -n '/LABEL/s/LABEL version=//p' Dockerfile)
  docker build -t "nierdz/$image:$version" .
  popd
done
