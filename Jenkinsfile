pipeline { 
    agent { label 'wsl' }
    stages {
        stage('init') {
            steps {
                echo 'Init..'
                sh "tasks/init.sh"  
            }
        }  
        stage('clone-repository') {
            steps {
                sh "tasks/git-clone.sh"  
                echo '..'  
            }
        } 
        stage('build-container') {
            steps {
                echo 'build-container..' 
                sh "tasks/buildah-rhtap.sh"  
            }
        }
        stage('acs-scans') {
            steps {
                echo 'acs-scans' 
                sh "tasks/acs-deploy-check.sh"  
                sh "tasks/acs-image-check.sh"  
                sh "tasks/acs-image-scan.sh"  
                
            }
        }
    }
}