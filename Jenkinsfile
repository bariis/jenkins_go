pipeline {
    agent { docker { image 'golang:1.16.6-alpine' } }
    stages {
        stage('build') {
            steps {
                sh 'go version'
            }
        }
    }
}
