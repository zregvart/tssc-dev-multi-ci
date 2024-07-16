
# Jenkins and RHTAP

This repository contains the innerloop development environment for the Jenkins translations from the RHTAP Pipelines.

The tasks appear in the `rhtap` directory and are updated manually. Once updated they can be tested locally in shell or pushed to the shared library and template repositories and tested in Jenkins as well as Developer Hub as part of RHTAP. 

## Development Mode 

In development mode, the pipeline script can be tested using local shell scripts.

`bash build-pipeline.sh` to run a build which will create the Image, SBOM and other artifacts 
`bash promote-pipeline` to run a promotion shell which will run Enterprise Contract.

The local exection requires binaries to be installed in your cluster on your path. The shell will print error message if any binaries are missing. 

## Release to Templates and Jenkins Library 

In order to run in RHTAP via software templates, you need to release to a fork of templates https://github.com/redhat-appstudio/tssc-sample-templates and install these into RHTAP. When validated in a fork, send a pull request to the release templates repo. 

In order to run the Jenkinsfile you must push to the Jenkins library https://github.com/redhat-appstudio/tssc-sample-jenkins
If you want to use a fork you must update your jenkinsfile to reference your fork repository in the jenkins file. 

```
library identifier: 'RHTAP_Jenkins@main', retriever: modernSCM(
  [$class: 'GitSCMSource',
   remote: 'https://github.com/redhat-appstudio/tssc-sample-jenkins.git'])
```

To update forks, in preparation for sending pull requests to the official library locations, you can run ` bash hack/copy-to-tssc-templates` to update your local forked repos and then manually check and push to your branch. 

## Jenkins mode

This repository is a Jenkins buildable repository. You manually create a `pipeline` project in Jenkins, and reference the Jenkinsfile in Jenkins.  You can then run a build.

## Configuring Jenkins

Binaries
The agent machines running jenkins (or if on master, that machine will need to have binaries configured for the jenkins user running the pipelines)

These will be checked prior to allowing execution to proceed. If any binaries are missing, there will be an error message printed. Install the required binary and re-run the shell mode or the jenkins agent. 

```
ENV vars:
OK: IMAGE_URL
OK: IMAGE
OK: QUAY_IO_CREDS_USR
OK: QUAY_IO_CREDS_PSW
OK: DISABLE_ACS
OK: GITOPS_AUTH_PASSWORD
OK: POLICY_CONFIGURATION
OK: REKOR_HOST
OK: IGNORE_REKOR
OK: INFO
OK: STRICT
OK: EFFECTIVE_TIME
OK: HOMEDIR
Binaries:
OK: git in /usr/bin/git
OK: curl in /usr/bin/curl
OK: jq in /usr/bin/jq
OK: yq in /usr/local/bin/yq
OK: buildah in /usr/bin/buildah
OK: syft in /mnt/g/wslbin/syft
OK: cosign in /usr/local/bin/cosign
OK: python3 in /usr/bin/python3
Env vars and binaries ok
```

The library requires some secrets to be defined in your Jenkins cluster

![alt text](creds.png "Title")



