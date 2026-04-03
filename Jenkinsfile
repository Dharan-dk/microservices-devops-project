pipeline {
    agent any

    environment {
        SONARQUBE_URL = "http://13.235.148.106:9000"
    }

    stages {

        stage('Checkout_SCM') {
            steps {
                echo "Checkout SCM"
                checkout scm
            }
        }

        stage('SonarQube_Analysis_User_Service') {
            steps {
                echo "Running SonarQube Analysis for User Service"
                withSonarQubeEnv('SonarQube') {
                    sh """
                        ${tool 'SonarScanner'}/bin/sonar-scanner \
                        -Dsonar.projectKey=user-service \
                        -Dsonar.sources=user-service \
                        -Dsonar.language=py \
                        -Dsonar.python.version=3.11 \
                        -Dsonar.host.url=${SONARQUBE_URL}
                    """
                }
            }
        }

        stage('SonarQube_Analysis_Order_Service') {
            steps {
                echo "Running SonarQube Analysis for Order Service"
                withSonarQubeEnv('SonarQube') {
                    sh """
                        ${tool 'SonarScanner'}/bin/sonar-scanner \
                        -Dsonar.projectKey=order-service \
                        -Dsonar.sources=order-service \
                        -Dsonar.language=py \
                        -Dsonar.python.version=3.11 \
                        -Dsonar.host.url=${SONARQUBE_URL}
                    """
                }
            }
        }

        stage('Quality_Gate') {
            steps {
                echo "Checking Quality Gate"
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        always {
            echo "This will always run"
        }
        success {
            echo "This will run only if the build is successful"
        }
        failure {
            echo "This will run only if the build fails"
        }
    }
}