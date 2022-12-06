#!/usr/bin/env bash

# WordPress bulk delete custom fields
#
# This script delete unwanted custom fields from all posts.
# You need to set these 3 variables to run it on your own WordPress:
# - META_KEYS
# - META_KEY_PATTERN
# - WP_BINARY
#
# If you run WordPress on docker, install wp-cli in your container first and run
# WP_BINARY="docker exec wordpress wp --allow-root" ./wordpress-bulk-delete-custom-fields.sh

set -o errexit
set -o pipefail
set -o nounset

DEBUG=${DEBUG:=0}
[[ $DEBUG -eq 1 ]] && set -o xtrace

# Simple meta keys
declare -a META_KEYS=(
  _aioseop_opengraph_settings
  _snap_forceSURL
  _wp_desired_post_slug
  _wp_old_slug
  snapEdIT
  snapEdIT
  snapFB
  snapImportedFBComments
  snapTW
  snap_MYURL
  snap_isAutoPosted
)

# Pattern of meta keys
declare -a META_KEYS_PATTERN=(
  _nxs_snap_*
  _oembed_*
  onesignal_*
)

# Define wp-cli binaray path and options
WP_BINARY=${WP_BINARY:="/usr/bin/wp --allow-root"}

echo "Retrieving all IDs from all posts"
IFS=$'\n' read -r -d '' -a POST_IDS < <(${WP_BINARY} post list --field=ID && printf '\0')

for id in "${POST_IDS[@]}"; do

  # Delete pattern meta keys
  echo "Reading meta keys from post ${id}"
  IFS=$'\n' read -r -d '' -a keys < <(${WP_BINARY} post meta list "${id}" --fields=meta_key && printf '\0')
  for key in "${keys[@]}"; do
    for pattern in "${META_KEYS_PATTERN[@]}"; do
      # shellcheck disable=SC2053
      if [[ "${key}" == ${pattern} ]]; then
        echo "Deleting ${key} matching ${pattern} in ${id}"
        ${WP_BINARY} post meta delete "${id}" "${key}"
      fi
    done
  done

  # Delete simple meta keys
  for key in "${keys[@]}"; do
    for simple_key in "${META_KEYS[@]}"; do
      if [[ "${key}" == "${simple_key}" ]]; then
        echo "Deleting ${key} matching ${simple_key} in ${id}"
        ${WP_BINARY} post meta delete "${id}" "${key}"
      fi
    done
  done

done
