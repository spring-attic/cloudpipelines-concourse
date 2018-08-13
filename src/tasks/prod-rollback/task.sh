#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

# synopsis {{{
# This script:
#
# * Sources default Cloud Pipelines Concourse scripts setup
# * Loads all git related functionality to allow tag manipulation
# * Calls the production rollback script of Cloud Pipelines script
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
echo "Concourse scripts resource folder is [${CONCOURSE_SCRIPTS_RESOURCE}]"
echo "Scripts resource folder is [${SCRIPTS_RESOURCE}]"
echo "Tools resource folder is [${CONCOURSE_SCRIPTS_RESOURCE}]"
echo "KeyVal resource folder is [${KEYVAL_RESOURCE}]"

# If you're using some other image with Docker change these lines
# shellcheck source=/dev/null
[ -f /docker-lib.sh ] && source /docker-lib.sh || echo "Failed to source docker-lib.sh... Hopefully you know what you're doing"
if [ -n "$(type -t timeout)" ] && [ "$(type -t timeout)" = function ]; then timeout 10s start_docker || echo "Failed to start docker... Hopefully you know what you're doing"; fi
if [ -n "$(type -t gtimeout)" ] && [ "$(type -t gtimeout)" = function ]; then gtimeout 10s start_docker || echo "Failed to start docker... Hopefully you know what you're doing"; fi

# shellcheck source=/dev/null
source "${ROOT_FOLDER}/${CONCOURSE_SCRIPTS_RESOURCE}/src/tasks/pipeline.sh"

echo "Deploying the built application on prod environment"
cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "Loading git key to enable tag deletion"
export TMPDIR=/tmp
echo "${GIT_PRIVATE_KEY}" > "${TMPDIR}/git-resource-private-key"
load_pubkey

# shellcheck source=/dev/null
. "${SCRIPTS_OUTPUT_FOLDER}"/prod_rollback.sh
