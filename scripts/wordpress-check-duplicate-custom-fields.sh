#!/usr/bin/env bash

# WordPress check for duplicate custom fields
#
# This script prints to stdout duplicate custom fields from all posts.
#
# If you run WordPress on docker, install wp-cli in your container first and run
# WP_BINARY="docker exec wordpress wp --allow-root" ./wordpress-check-duplicate-custom-fields.sh

set -o errexit
set -o pipefail
set -o nounset

DEBUG=${DEBUG:=0}
[[ $DEBUG -eq 1 ]] && set -o xtrace

# Define wp-cli binaray path and options
WP_BINARY=${WP_BINARY:="docker exec madrabbit-wordpress /usr/bin/wp --allow-root"}

echo "Retrieving all IDs from all posts"
IFS=$'\n' read -r -d '' -a POST_IDS < <(${WP_BINARY} post list --field=ID && printf '\0')

for id in "${POST_IDS[@]}"; do

  echo "Reading meta keys from post ${id}"
  IFS=$'\n' read -r -d '' -a keys < <(${WP_BINARY} post meta list "${id}" --fields=meta_key | sort | uniq -d && printf '\0')
  for key in "${keys[@]}"; do
    echo "The custom post field ${key} is duplicated on post ${id}"
  done

done
