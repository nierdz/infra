#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

DEBUG=${DEBUG:=0}
[[ $DEBUG -eq 1 ]] && set -o xtrace
DOCKER_PASSWORD=${DOCKER_PASSWORD:-}

# Generate token to interact with docker hub API
DOCKER_TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d "{\"username\": \"nierdz\", \"password\": \"$DOCKER_PASSWORD\"}" "https://hub.docker.com/v2/users/login/" | jq -r .token)

function push_readme() {
  code=$(jq -n --arg msg "$(<README.md)" \
    '{"registry":"registry-1.docker.io","full_description": $msg }' |
    curl -s -o /dev/null -L -w "%{http_code}" \
      "https://hub.docker.com/v2/repositories/nierdz/${image}/" \
      -d @- -X PATCH \
      -H "Content-Type: application/json" \
      -H "Authorization: JWT ${DOCKER_TOKEN}")

  if [[ "${code}" = "200" ]]; then
    printf "Successfully pushed README to Docker Hub"
  else
    printf "Unable to push README to Docker Hub, response code: %s\n" "${code}"
    exit 1
  fi
}

pushd "$GITHUB_WORKSPACE/docker"
for image in */; do
  image="${image%/}"
  pushd "$image"
  version=$(sed -n '/LABEL/s/LABEL version=//p' Dockerfile)
  echo "$DOCKER_PASSWORD" | docker login -u "nierdz" --password-stdin
  docker tag "nierdz/$image:$version" "nierdz/$image:latest"
  docker push "nierdz/$image:$version"
  docker push "nierdz/$image:latest"
  push_readme
  popd
done
popd
