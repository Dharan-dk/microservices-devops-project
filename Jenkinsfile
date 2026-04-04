pipeline {
    agent any

    environment {
        VENV = "venv"
        PYTHON = "python3"
    }

    options {
        timestamps()
        skipDefaultCheckout(true)
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Environment') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    sh """
                        ${PYTHON} -m venv ${VENV}
                        . ${VENV}/bin/activate
                        pip install --upgrade pip
                    """
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    sh """
                        . ${VENV}/bin/activate
                        pip install -r user-service/requirements.txt
                        pip install -r order-service/requirements.txt
                    """
                }
            }
        }

        stage('Test + Coverage') {
            parallel {

                stage('User Service') {
                    steps {
                        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                            sh """
                                . ${VENV}/bin/activate
                                pytest user-service/tests \
                                --cov=user-service/app \
                                --cov-report=xml:user-service/coverage.xml \
                                --junitxml=user-service/test-results.xml
                            """
                            junit 'user-service/test-results.xml'
                        }
                    }
                }

                stage('Order Service') {
                    steps {
                        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                            sh """
                                . ${VENV}/bin/activate
                                pytest order-service/tests \
                                --cov=order-service/app \
                                --cov-report=xml:order-service/coverage.xml \
                                --junitxml=order-service/test-results.xml
                            """
                            junit 'order-service/test-results.xml'
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {

                withSonarQubeEnv('SonarQube') {

                    sh """
                        ${tool 'SonarQube'}/bin/sonar-scanner \
                        -Dsonar.projectKey=user-service \
                        -Dsonar.sources=user-service \
                        -Dsonar.python.version=3.11 \
                        -Dsonar.python.coverage.reportPaths=user-service/coverage.xml
                    """

                    sh """
                        ${tool 'SonarQube'}/bin/sonar-scanner \
                        -Dsonar.projectKey=order-service \
                        -Dsonar.sources=order-service \
                        -Dsonar.python.version=3.11 \
                        -Dsonar.python.coverage.reportPaths=order-service/coverage.xml
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }

        success {
            echo 'Build succeeded and passed SonarQube quality gate.'
        }

        failure {
            echo 'Build failed or did not pass SonarQube quality gate.'
        }
    }
}