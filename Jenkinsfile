library identifier: 'RHTAP_Jenkins@main', retriever: modernSCM(
  [$class: 'GitSCMSource',
   remote: 'https://github.com/redhat-appstudio/tssc-sample-jenkins.git'])
   

pipeline { 
    agent any
    environment {
        ROX_API_TOKEN     = credentials('ROX_API_TOKEN')
        ROX_CENTRAL_ENDPOINT = credentials('ROX_CENTRAL_ENDPOINT')
        GITOPS_AUTH_PASSWORD = credentials('GITOPS_AUTH_PASSWORD')
        QUAY_IO_CREDS = credentials('QUAY_IO_CREDS')
        COSIGN_SECRET_PASSWORD = credentials('COSIGN_SECRET_PASSWORD')
        COSIGN_SECRET_KEY = credentials('COSIGN_SECRET_KEY')
        COSIGN_PUBLIC_KEY = credentials('COSIGN_PUBLIC_KEY')
    }   
    stages { 
        stage('init.sh') {
            steps {
                script { 
                    rhtap.info ("Init")
                    rhtap.init() 
                }
            }
        } 
        stage('build') {
            steps {
                script { 
                    rhtap.info( 'build_container..') 
                    rhtap.buildah_rhtap()  
                }
            }
        }
        stage('sign-attest') {
            steps {
                script {
                    rhtap.info('sign_attest..')
                    // Todo:
                    // rhtap.cosign_sign_attest()
                }
            }
        }
        stage('scan') {
            steps {
                script { 
                    rhtap.info('acs_scans' )
                    rhtap.acs_deploy_check()  
                    rhtap.acs_image_check()  
                    rhtap.acs_image_scan()  
                }
            }
        }
        stage('deploy') {
            steps {
                script { 
                    rhtap.info('deploy' ) 
                    rhtap.update_deployment()  
                }
            }
        }
        stage('summary') {
            steps {
                script { 
                    rhtap.info('summary' )  
                    rhtap.show_sbom_rhdh()  
                    rhtap.summary()  
                }
            }
        }
    }
}