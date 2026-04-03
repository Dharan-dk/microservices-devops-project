pipeline {
    agent any

    stages {

        stage('Checkout SCM') {
            steps {
                echo "Cloning repository"
                checkout scm
            }
        }

        stage('User Service - SonarQube Analysis') {
            steps {
                echo "Analyzing user-service"
                withSonarQubeEnv('SonarQube') {
                    sh """
                        ${tool 'SonarScanner'}/bin/sonar-scanner \
                        -Dsonar.projectKey=user-service \
                        -Dsonar.sources=user-service
                    """
                }
            }
        }

        stage('User Service - Quality Gate') {
            steps {
                echo "Waiting for user-service Quality Gate"
                timeout(time: 3, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Order Service - SonarQube Analysis') {
            steps {
                echo "Analyzing order-service"
                withSonarQubeEnv('SonarQube') {
                    sh """
                        ${tool 'SonarScanner'}/bin/sonar-scanner \
                        -Dsonar.projectKey=order-service \
                        -Dsonar.sources=order-service
                    """
                }
            }
        }

        stage('Order Service - Quality Gate') {
            steps {
                echo "Waiting for order-service Quality Gate"
                timeout(time: 3, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning workspace"
            cleanWs()
        }
        success {
            echo "ALL SERVICES PASSED QUALITY GATES SUCCESSFULLY"
        }
        failure {
            echo "PIPELINE FAILED DUE TO QUALITY GATE FAILURE"
        }
    }
}