pipeline { 
    stages {
        stage('Build') {
            steps {
                echo 'Building..'
                sh  'ls -al'
                sh 'echo Build > build.results' 
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
                sh  'ls -al'
                sh 'echo Test > test.results'  
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
                sh  'ls -al'
                sh 'echo Deploy > deploy.results'  
            }
        }
    }
}