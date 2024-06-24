#!/bin/bash
# verify-enterprise-contract

# Top level parameters 
export VERIFY_ENTERPRISE_CONTRACT_PARAM_IMAGES=
export VERIFY_ENTERPRISE_CONTRACT_PARAM_POLICY_CONFIGURATION=
export VERIFY_ENTERPRISE_CONTRACT_PARAM_PUBLIC_KEY=
export VERIFY_ENTERPRISE_CONTRACT_PARAM_REKOR_HOST=
export VERIFY_ENTERPRISE_CONTRACT_PARAM_IGNORE_REKOR=
export VERIFY_ENTERPRISE_CONTRACT_PARAM_TUF_MIRROR=
export VERIFY_ENTERPRISE_CONTRACT_PARAM_SSL_CERT_DIR=
export VERIFY_ENTERPRISE_CONTRACT_PARAM_INFO=
export VERIFY_ENTERPRISE_CONTRACT_PARAM_STRICT=
export VERIFY_ENTERPRISE_CONTRACT_PARAM_HOMEDIR=
export VERIFY_ENTERPRISE_CONTRACT_PARAM_EFFECTIVE_TIME=


function version() {
	echo "Running  version"
	ec
}

function initialize-tuf() {
	echo "Running  initialize-tuf"
	set -euo pipefail
	
	if [[ -z "${TUF_MIRROR:-}" ]]; then
	    echo 'TUF_MIRROR not set. Skipping TUF root initialization.'
	    exit
	fi
	
	echo 'Initializing TUF root...'
	cosign initialize --mirror "${TUF_MIRROR}" --root "${TUF_MIRROR}/root.json"
	echo 'Done!'
}

function validate() {
	echo "Running  validate"
	ec
}

function report() {
	echo "Running  report"
	cat
}

function report-json() {
	echo "Running  report-json"
	cat
}

function summary() {
	echo "Running  summary"
	jq
}

function assert() {
	echo "Running  assert"
	jq
}

function annotate-task() {
	echo "Running  annotate-task"
	#!/usr/bin/env bash
	echo "verify-enterprise-contract $(context.taskRun.name)"
	oc annotate taskrun $(context.taskRun.name) task.results.format=application/json
	oc annotate taskrun $(context.taskRun.name) task.results.type=ec
	oc annotate taskrun $(context.taskRun.name) task.results.container=step-report-json
	oc annotate taskrun $(context.taskRun.name) task.output.location=logs
	
}

# Task Steps 
version
initialize-tuf
validate
report
report-json
summary
assert
annotate-task
