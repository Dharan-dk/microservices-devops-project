pipeline {
    agent any

    environment {
        VENV  = "venv"
        PYTHON = "python3"

        AWS_REGION          = "ap-south-1"
        ECR_REGISTRY        = "204844252943.dkr.ecr.ap-south-1.amazonaws.com"
        USER_SERVICE_IMAGE  = "${ECR_REGISTRY}/cloudmart-user-service"
        ORDER_SERVICE_IMAGE = "${ECR_REGISTRY}/cloudmart-order-service"
        IMAGE_TAG           = "${BUILD_NUMBER}"
    }

    options {
        timestamps()
        skipDefaultCheckout(true)
    }

    stages {

        stage('Verfiy agent') {
            agent {
                label 'static-agent'
            }

            steps {
                echo "Running on agent: ${env.NODE_NAME}"
                sh """
                    python3 --version
                    docker --version
                    aws --version
                    trivy --version
                    hostname
                    whoami
                    java -version
                """
            }
        }

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
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
                        ${tool 'SonarScanner'}/bin/sonar-scanner \
                            -Dsonar.projectKey=user-service \
                            -Dsonar.sources=user-service \
                            -Dsonar.python.version=3.11 \
                            -Dsonar.python.coverage.reportPaths=user-service/coverage.xml
                    """
                    sh """
                        ${tool 'SonarScanner'}/bin/sonar-scanner \
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

        stage('Docker Build') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id',
                               variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key',
                               variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh """
                            aws ecr get-login-password \
                                --region ${AWS_REGION} \
                            | docker login \
                                --username AWS \
                                --password-stdin ${ECR_REGISTRY}

                            docker build \
                                -t ${USER_SERVICE_IMAGE}:${IMAGE_TAG} \
                                -f user-service/Dockerfile \
                                user-service/

                            docker build \
                                -t ${ORDER_SERVICE_IMAGE}:${IMAGE_TAG} \
                                -f order-service/Dockerfile \
                                order-service/
                        """
                    }
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    sh """
                        trivy image \
                            --exit-code 1 \
                            --severity HIGH,CRITICAL \
                            --no-progress \
                            ${USER_SERVICE_IMAGE}:${IMAGE_TAG}

                        trivy image \
                            --exit-code 1 \
                            --severity HIGH,CRITICAL \
                            --no-progress \
                            ${ORDER_SERVICE_IMAGE}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Push to ECR') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id',
                               variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key',
                               variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh """
                            aws ecr get-login-password \
                                --region ${AWS_REGION} \
                            | docker login \
                                --username AWS \
                                --password-stdin ${ECR_REGISTRY}

                            docker push ${USER_SERVICE_IMAGE}:${IMAGE_TAG}
                            docker push ${ORDER_SERVICE_IMAGE}:${IMAGE_TAG}

                            docker tag \
                                ${USER_SERVICE_IMAGE}:${IMAGE_TAG} \
                                ${USER_SERVICE_IMAGE}:latest
                            docker tag \
                                ${ORDER_SERVICE_IMAGE}:${IMAGE_TAG} \
                                ${ORDER_SERVICE_IMAGE}:latest

                            docker push ${USER_SERVICE_IMAGE}:latest
                            docker push ${ORDER_SERVICE_IMAGE}:latest
                        """
                    }
                }
            }
        }

    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Build succeeded. Images pushed to ECR.'
        }
        failure {
            echo 'Build failed. Check logs for details.'
        }
    }

} 