pipeline { 
    agent { label 'wsl' }
    stages {
        stage('Build') {
            steps {
                echo 'Building..' 
                sh "ls -al"
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..' 
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....' 
            }
        }
    }
}