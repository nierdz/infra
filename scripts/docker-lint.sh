#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

DEBUG=${DEBUG:=0}
[[ $DEBUG -eq 1 ]] && set -o xtrace

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

pushd "$DIR/../docker"

DOCKERFILES=$(find . -name "Dockerfile")

fail=0
for file in $DOCKERFILES; do
  if lint_outpout=$(docker run \
    --rm -i hadolint/hadolint \
    hadolint - <"$file" 2>&1); then
    status='[OK]'
  else
    status='[FAIL]'
    fail=1
  fi

  echo "${status} ${file}"
  [[ -n $lint_outpout ]] && echo "$lint_outpout"
done

if [[ $fail -ne 0 ]]; then
  exit 1
fi
