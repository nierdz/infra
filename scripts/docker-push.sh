#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

DEBUG=${DEBUG:=0}
[[ $DEBUG -eq 1 ]] && set -o xtrace
DOCKER_PASSWORD=${DOCKER_PASSWORD:-}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function docker_tag_exists() {
  docker_token=$(curl -s -H "Content-Type: application/json" -X POST -d "{\"username\": \"nierdz\", \"password\": \"$DOCKER_PASSWORD\"}" "https://hub.docker.com/v2/users/login/" | jq -r .token)
  docker_tag=$(curl -s -H "Authorization: JWT ${docker_token}" "https://hub.docker.com/v2/repositories/$1/tags/?page_size=10000" | jq -r "[.results | .[] | .name == \"$2\"] | any")
  test "$docker_tag" = true
}

pushd "$DIR/../docker"
for image in */; do
  image="${image%/}"
  pushd "$image"
  version=$(sed -n '/LABEL/s/LABEL version=//p' Dockerfile)
  if docker_tag_exists "nierdz/$image" "$version"; then
      echo "$image:$version already exists on docker hub, do not push"
  else
    echo "$image:$version does not exists on docker hub, let's push it !"
    echo "$DOCKER_PASSWORD" | docker login -u "nierdz" --password-stdin
    docker push "nierdz/$image:$version"
  fi
  popd
done
