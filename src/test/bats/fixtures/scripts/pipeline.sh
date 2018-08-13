#!/bin/bash
function retrieveGroupId() {
	echo "com.example"
}

function retrieveAppName() {
    echo "${PROJECT_NAME}"
}

function retrieveStubRunnerIds() {
    echo "com.example:foo:1.0.0.RELEASE:stubs:1234"
}

function deleteService() {
    echo "$*"
}

function deployService() {
    echo "$*" 
}

function outputFolder() {
    echo "target/"
}

function testResultsAntPattern() {
    echo "**/test-results/*.xml"
}

# ---- BUILD PHASE ----
function build() {
    echo "build"
}

function executeApiCompatibilityCheck() {
    echo "executeApiCompatibilityCheck"
}

# ---- TEST PHASE ----

function testDeploy() {
    echo "testDeploy"
}

function testRollbackDeploy() {
    echo "testRollbackDeploy [${1}]"
}

function prepareForSmokeTests() {
    echo "prepareForSmokeTests"
}

function runSmokeTests() {
    echo "runSmokeTests"
}

# ---- STAGE PHASE ----

function stageDeploy() {
    echo "stageDeploy"
}

function prepareForE2eTests() {
    echo "prepareForE2eTests"
}

function runE2eTests() {
    echo "runE2eTests"
}

# ---- PRODUCTION PHASE ----

function prodDeploy() {
    echo "prodDeploy"
}

function completeSwitchOver() {
    echo "completeSwitchOver"
}

function rollbackToPreviousVersion() {
    echo "rollbackToPreviousVersion"
}

function removeProdTag() {
    echo "removeProdTag"
}

function projectType() {
	echo "projectType"
}

function findLatestProdTag() {
	echo "findLatestProdTag"
}

function latestProdTagFromGit() {
	echo "latestProdTagFromGit"
}

function trimRefsTag() {
	echo "trimRefsTag"
}

function extractVersionFromProdTag() {
	echo "extractVersionFromProdTag"
}

function parsePipelineDescriptor() {
	echo "parsePipelineDescriptor"
}

function deployServices() {
	echo "deployServices"
}

function envNodeExists() {
	echo "envNodeExists"
}

function yaml2json() {
	echo "yaml2json"
}

function toLowerCase() {
	echo "toLowerCase"
}

function getMainModulePath() {
	echo "getMainModulePath"
}

function defineProjectSetup() {
	echo "defineProjectSetup"
}

echo "pipeline.sh sourced"
