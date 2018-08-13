#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

# synopsis {{{
# Contains default setup for a generic Cloud Pipelines Concourse step
#
# * Sources the default setup for all Cloud Pipelines Concourse scripts
# * Executes the passed script to run
# * Passes properties via key-value Concourse resource
#
# }}}

export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export REPO_RESOURCE=repo
export CONCOURSE_SCRIPTS_RESOURCE=concourse
export SCRIPTS_RESOURCE=scripts
export KEYVAL_RESOURCE=keyval
export KEYVALOUTPUT_RESOURCE=keyvalout
export OUTPUT_RESOURCE=out

echo "Root folder is [${ROOT_FOLDER}]"
echo "Repo resource folder is [${REPO_RESOURCE}]"
echo "Concourse scripts resource folder is [${CONCOURSE_SCRIPTS_RESOURCE}]"
echo "Scripts resource folder is [${SCRIPTS_RESOURCE}]"
echo "KeyVal resource folder is [${KEYVAL_RESOURCE}]"

# If you're using some other image with Docker change these lines
# shellcheck source=/dev/null
[ -f /docker-lib.sh ] && source /docker-lib.sh || echo "Failed to source docker-lib.sh... Hopefully you know what you're doing"
if [ -n "$(type -t timeout)" ] && [ "$(type -t timeout)" = function ]; then timeout 10s start_docker || echo "Failed to start docker... Hopefully you know what you're doing"; fi
if [ -n "$(type -t gtimeout)" ] && [ "$(type -t gtimeout)" = function ]; then gtimeout 10s start_docker || echo "Failed to start docker... Hopefully you know what you're doing"; fi

# shellcheck source=/dev/null
source "${ROOT_FOLDER}/${CONCOURSE_SCRIPTS_RESOURCE}/src/tasks/pipeline.sh"

echo "${MESSAGE}"
cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

# shellcheck source=/dev/null
. "${SCRIPTS_OUTPUT_FOLDER}/${SCRIPT_TO_RUN}"

passKeyValProperties
