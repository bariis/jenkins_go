pipeline {
    agent any
    tools {
        go 'go1.16'
    }
    environment {
        GO111MODULE = 'auto'
        CGO_ENABLED = 0 
        GOPATH = "${JENKINS_HOME}/jobs/${JOB_NAME}/builds/${BUILD_ID}"
        registry = "barisertas/new_jenkins"
        registryCredential = "dockerhub_id3"
        dockerImage = ""
    }
    stages {        
//         stage('Pre Test') {
//             steps {
//                 echo 'Installing dependencies'
//                 sh 'go version'
//                 sh 'go get -u golang.org/x/lint/golint'
//             }
//         }
        stage('Build') {
            steps {
                echo 'Compiling and building'
                sh 'go build'
            }
        }

        stage('Test') {
            steps {
                withEnv(["PATH+GO=${GOPATH}/bin"]){
                    echo 'Running test'
                    sh 'go test -v'
                }
            }
        }   
        
        stage('Create Image') {
            steps {
                script {
                    dockerImage = docker.build registry + ":$BUILD_NUMBER"
                }
            }
        }
        
        stage('Publish') {
            steps {
                script {
                    docker.withRegistry('', registryCredential) {
                        dockerImage.push()
                    }
                }
            }
        }
    }
}
