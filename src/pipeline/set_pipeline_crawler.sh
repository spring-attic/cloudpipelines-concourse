#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

# tag::envs[]
# root URL of the SCM server's API
export CRAWLER_ROOTURL="${CRAWLER_ROOTURL:-https://github.com}"
# username to connect to the API
export CRAWLER_USERNAME="${CRAWLER_USERNAME:-}"
# password to connect to the API
export CRAWLER_PASSWORD="${CRAWLER_PASSWORD:-}"
# token to connect to the API
export CRAWLER_TOKEN="${CRAWLER_TOKEN:-}"
# pattern to exclude certain projects
export CRAWLER_REPOPROJECTSEXCLUDEPATTERN="${CRAWLER_REPOPROJECTSEXCLUDEPATTERN:-}"
# type of SCM repo server (GITHUB, GITLAB, BITBUCKET, OTHER). Can be resolved from URL
export CRAWLER_REPOTYPE="${CRAWLER_REPOTYPE:-}"
# name of the pipeline descriptor
export CRAWLER_ORG="${CRAWLER_ORG:-}"
# organization / project name
export CRAWLER_PIPELINEDESCRIPTOR="${CRAWLER_PIPELINEDESCRIPTOR:-}"
# alias to be used by FLY CLI to set the pipeline
export CRAWLER_ALIAS="${CRAWLER_ALIAS:-}"
# credentials file to be used by FLY CLI to set the pipeline
export CRAWLER_CREDENTIALS="${CRAWLER_CREDENTIALS:-}"
# end::envs[]

echo "Will verify if Groovy is installed"
export GROOVY_BIN="${GROOVY_BIN:-groovy}"
export GROOVY_VERSION="${GROOVY_VERSION:-2.5.2}"
export GROOVY_DOWNLOAD_URL="${GROOVY_DOWNLOAD_URL:-https://bintray.com/artifact/download/groovy/maven/apache-groovy-binary-${GROOVY_VERSION}.zip}"
"${GROOVY_BIN}" --version && GROOVY_INSTALLED="true" || echo "Groovy is missing!"
if [[ "${GROOVY_INSTALLED}" != "true" ]]; then
	echo "Groovy is not available, will download it from [${GROOVY_DOWNLOAD_URL}]"
	GROOVY_HOME="$(pwd)/build/groovy-${GROOVY_VERSION}"
	GROOVY_BIN="${GROOVY_HOME}/bin/groovy"
	if [[ ! -f "${GROOVY_BIN}" ]]; then
		mkdir -p build
		wget "${GROOVY_DOWNLOAD_URL}" -O build/groovy.zip
		unzip build/groovy.zip -d build/
	fi
	echo "Groovy binary available at [${GROOVY_BIN}]"
fi

echo -e "\n\nRunning project crawler, please wait while dependencies are fetched\n\n"

"${GROOVY_BIN}" crawler.groovy

echo "DONE!"
