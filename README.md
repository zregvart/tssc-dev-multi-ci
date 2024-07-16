
# Jenkins and RHTAP

This repository contains the innerloop development environment for the Jenkins translations from the RHTAP Pipelines.

The tasks appear in the `rhtap` directory and are updated manually. 

## Development Mode 

In development mode, the pipeline script can be tested using local shell scripts.

`bash build-pipeline.sh`  to run a build
`bash promote-pipeline` to run a promotion shell which will run Enterprise Contract.


## Release to Templates and Jenkins Library 

In order to run in RHTAP via software templates, you need to release to a branch of the templates https://github.com/redhat-appstudio/tssc-sample-templates 
In order to run the Jenkinsfile you must push to the Jenkins library (or your fork)  https://github.com/redhat-appstudio/tssc-sample-jenkins 


Run  ` bash hack/copy-to-tssc-templates` to update your local clones and the manually check and push to your branch. 

# Jenkins mode

This repository is a Jenkins buildable repository. You can create a `pipeline` project in jenkins, and reference the Jenkinsfile in Jenkins.  You can then run a build.


