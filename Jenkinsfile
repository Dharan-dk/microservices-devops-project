pipeline {
    agent none

    environment {
        VENV                = "venv"
        PYTHON              = "python3"
        AWS_REGION          = "ap-south-1"
        ECR_REGISTRY        = "204844252943.dkr.ecr.ap-south-1.amazonaws.com"
        USER_SERVICE_IMAGE  = "${ECR_REGISTRY}/cloudmart-user-service"
        ORDER_SERVICE_IMAGE = "${ECR_REGISTRY}/cloudmart-order-service"
        IMAGE_TAG           = "${BUILD_NUMBER}"
        EKS_CLUSTER_NAME    = "cloudmart-eks-cluster"
    }

    options {
        timestamps()
        skipDefaultCheckout(true)
    }

    stages {

        stage('Checkout') {
            agent { label 'static-agent' }
            steps {
                echo "Checking out on: ${env.NODE_NAME}"
                checkout scm
                stash(
                    name: 'source-code',
                    includes: '''
                        user-service/**,
                        order-service/**,
                        k8s/**,
                        .trivyignore,
                        Jenkinsfile,
                        sonar-project.properties
                    '''
                )
            }
        }

        stage('Test & Quality') {
            agent { label 'static-agent' }
            stages {

                stage('Setup Environment') {
                    steps {
                        unstash 'source-code'
                        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                            sh """
                                ${PYTHON} -m venv ${VENV}
                                . ${VENV}/bin/activate
                                pip install --upgrade pip --quiet
                            """
                        }
                    }
                }

                stage('Install Dependencies') {
                    steps {
                        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                            sh """
                                . ${VENV}/bin/activate
                                pip install --quiet \
                                    -r user-service/requirements.txt
                                pip install --quiet \
                                    -r order-service/requirements.txt
                            """
                        }
                    }
                }

                stage('Test + Coverage') {
                    parallel {
                        stage('User Service Tests') {
                            steps {
                                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                    sh """
                                        . ${VENV}/bin/activate
                                        pytest user-service/tests \
                                            --cov=user-service/app \
                                            --cov-report=xml:user-service/coverage.xml \
                                            --junitxml=user-service/test-results.xml \
                                            -q
                                    """
                                    junit 'user-service/test-results.xml'
                                }
                            }
                        }
                        stage('Order Service Tests') {
                            steps {
                                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                    sh """
                                        . ${VENV}/bin/activate
                                        pytest order-service/tests \
                                            --cov=order-service/app \
                                            --cov-report=xml:order-service/coverage.xml \
                                            --junitxml=order-service/test-results.xml \
                                            -q
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
            }
        }

        stage('Build & Push') {
            agent { label 'static-agent' }
            stages {

                stage('Docker Build') {
                    steps {
                        unstash 'source-code'
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
                                    --ignorefile .trivyignore \
                                    ${USER_SERVICE_IMAGE}:${IMAGE_TAG}

                                trivy image \
                                    --exit-code 1 \
                                    --severity HIGH,CRITICAL \
                                    --no-progress \
                                    --ignorefile .trivyignore \
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
        }

        // ── CD STAGES — Separate from CI ─────────────────────────
        stage('Deploy to EKS') {
            agent { label 'static-agent' }
            steps {
                unstash 'source-code'
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id',
                               variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key',
                               variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh """
                            # Configure kubectl for this build
                            aws eks update-kubeconfig \
                                --region ${AWS_REGION} \
                                --name ${EKS_CLUSTER_NAME}

                            # Create namespace if not exists
                            kubectl apply -f k8s/namespace.yaml

                            # Deploy user-service with current build tag
                            export IMAGE_TAG=${IMAGE_TAG}
                            export ECR_REGISTRY=${ECR_REGISTRY}

                            envsubst < k8s/user-service/deployment.yaml \
                                | kubectl apply -f -
                            kubectl apply -f k8s/user-service/service.yaml

                            # Deploy order-service with current build tag
                            envsubst < k8s/order-service/deployment.yaml \
                                | kubectl apply -f -
                            kubectl apply -f k8s/order-service/service.yaml
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            agent { label 'static-agent' }
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id',
                               variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key',
                               variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh """
                            aws eks update-kubeconfig \
                                --region ${AWS_REGION} \
                                --name ${EKS_CLUSTER_NAME}

                            # Wait for rollout to complete
                            kubectl rollout status deployment/user-service \
                                -n cloudmart --timeout=300s

                            kubectl rollout status deployment/order-service \
                                -n cloudmart --timeout=300s

                            # Show final status
                            echo "=== Pods ==="
                            kubectl get pods -n cloudmart

                            echo "=== Services (LoadBalancer URLs) ==="
                            kubectl get svc -n cloudmart
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            node('static-agent') {
                cleanWs()
            }
        }
        success {
            echo 'Build succeeded. Images in ECR. App deployed to EKS.'
        }
        unstable {
            echo 'Build unstable. Check Trivy or test results.'
        }
        failure {
            echo 'Build failed. Check logs for details.'
        }
    }
}