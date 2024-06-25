pipeline { 
    agent { label 'wsl' }
    stages {
        stage('init') {
            steps {
                echo 'Init..' 
                sh "ls -al"  
                sh "tasks/init.sh"  
            }
        }  
        stage('build) {
            steps {
                echo 'build-container..' 
                sh "tasks/buildah-rhtap.sh"  
            }
        }
        stage('scan') {
            steps {
                echo 'acs-scans' 
                sh "tasks/acs-deploy-check.sh"  
                sh "tasks/acs-image-check.sh"  
                sh "tasks/acs-image-scan.sh"  
                
            }
        }
        stage('deploy') {
            steps {
                echo 'build-container..' 
                sh "tasks/update-deployment.sh"  
            }
        }
    }
}