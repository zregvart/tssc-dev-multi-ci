pipeline { 
    agent { label 'wsl' }
    stages {
        stage('Build') {
            steps {
                echo 'Building..' 
                sh "ls -al"
                echo 'ls' 
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