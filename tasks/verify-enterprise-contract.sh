# verify-enterprise-contract

# Parameters 
export IMAGES=
export POLICY_CONFIGURATION=
export PUBLIC_KEY=
export REKOR_HOST=
export IGNORE_REKOR=
export TUF_MIRROR=
export SSL_CERT_DIR=
export INFO=
export STRICT=
export HOMEDIR=
export EFFECTIVE_TIME=


function version() {
version

undefined
}

function initialize-tuf() {
initialize-tuf

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
validate

undefined
}

function report() {
report

undefined
}

function report-json() {
report-json

undefined
}

function summary() {
summary

undefined
}

function assert() {
assert

undefined
}

function annotate-task() {
annotate-task

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
