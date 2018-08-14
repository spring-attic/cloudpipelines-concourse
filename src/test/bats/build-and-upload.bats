#!/usr/bin/env bats

load 'test_helper'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
	export TEMP_DIR="$( mktemp -d )"

	cp -a "${FIXTURES_DIR}/generic" "${TEMP_DIR}"

	# Copying the common folder
	NEW_SRC="${TEMP_DIR}/generic/project/scripts/src/main/bash"
	mkdir -p "${NEW_SRC}"
	export PAAS_TYPE="cf"
	echo "Copying [${COMMON_DIR}/] to [${NEW_SRC}] for test"
	cp -r  "${COMMON_DIR}/" "${NEW_SRC}"
	cp -f "${FIXTURES_DIR}/pipeline-dummy.sh" "${NEW_SRC}/pipeline-cf.sh"

	# Copying the concourse folder
	NEW_CONCOURSE_SRC="${TEMP_DIR}/generic/project/concourse/"
	mkdir -p "${NEW_CONCOURSE_SRC}"
	cp -r "${SOURCE_DIR}" "${NEW_CONCOURSE_SRC}"

	export ROOT_FOLDER="${TEMP_DIR}/generic/project"
	export REPO_RESOURCE="repo"
	export CONCOURSE_SCRIPTS_RESOURCE=concourse
    export SCRIPTS_RESOURCE=scripts
	export KEYVAL_RESOURCE="keyval"
	export M2_HOME="${TEMP_DIR}/generic/project/user_home"
	export GRADLE_HOME="${TEMP_DIR}/generic/project/user_home"
	export SSH_HOME="${TEMP_DIR}/generic/project/ssh"
	mkdir -p "${SSH_HOME}"
	export TEST_MODE="true"
	export SSH_AGENT_BIN="stubbed-ssh-agent"
	export TMPDIR="${TEMP_DIR}/generic/project/tmp"
	mkdir -p "${TMPDIR}"

	mv "${ROOT_FOLDER}"/repo/git "${ROOT_FOLDER}"/repo/.git
}

teardown() {
	rm -rf "${TEMP_DIR}"
}

@test "should run the build-and-upload task and tag the repo" {
	export PROJECT_NAME="app-monolith"
	cd "${ROOT_FOLDER}"

	run "${ROOT_FOLDER}"/concourse/src/tasks/build-and-upload/task.sh

	assert_success
	assert_output --partial "Executed build_api_compatibility_check"
	assert_output --partial "Executed build_and_upload"
}
