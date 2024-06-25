pipeline { 
    agent { label 'wsl' }
    stages {
        stage('build') {
            steps {
                echo 'build-container..' 
                sh "rhtap/buildah-rhtap.sh"  
            }
        }
        stage('scan') {
            steps {
                echo 'acs-scans' 
                sh "rhtap/acs-deploy-check.sh"  
                sh "rhtap/acs-image-check.sh"  
                sh "rhtap/acs-image-scan.sh"  
            }
        }
        stage('deploy') {
            steps {
                echo 'deploy' 
                sh "rhtap/update-deployment.sh"  
            }
        }stage('summary') {
            steps {
                echo 'summary' 
                sh "rhtap/summary.sh"  
                sh "rhtap/show-sbom-rhdh.sh"  
            }
        }
    }
}