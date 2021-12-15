pipeline {
    agent any
    tools {
        go 'go1.16'
    }
    environment {
        GO111MODULE = 'on'
    }
    stages {
        stage('Compile') {
		agent {
			docker {
				image 'golang:1.16-alpine'
			}
		}
            steps {
		'go build'
            }
        }   
    }
}
