pipeline {
    agent { label 'static-agent' }

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
    }

    stages {

        // ── CHECKOUT ─────────────────────────────
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // ── SETUP ENV ────────────────────────────
        stage('Setup Environment') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                '''
            }
        }

        // ── INSTALL DEPENDENCIES ─────────────────
        stage('Install Dependencies') {
            steps {
                sh '''
                    . venv/bin/activate
                    pip install -r user-service/requirements.txt
                    pip install -r order-service/requirements.txt
                    pip install pytest pytest-cov
                '''
            }
        }

        // ── TEST + COVERAGE ──────────────────────
        stage('Test + Coverage') {
            parallel {

                stage('User Service Tests') {
                    steps {
                        sh '''
                            . venv/bin/activate
                            pytest user-service/tests \
                              --cov=user-service/app \
                              --cov-report=xml:user-service/coverage.xml \
                              --junitxml=user-service/test-results.xml -q
                        '''
                        junit 'user-service/test-results.xml'
                    }
                }

                stage('Order Service Tests') {
                    steps {
                        sh '''
                            . venv/bin/activate
                            pytest order-service/tests \
                              --cov=order-service/app \
                              --cov-report=xml:order-service/coverage.xml \
                              --junitxml=order-service/test-results.xml -q
                        '''
                        junit 'order-service/test-results.xml'
                    }
                }
            }
        }

        // ── SONAR ANALYSIS ───────────────────────
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

        // ── QUALITY GATE ─────────────────────────
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // ── DOCKER BUILD ─────────────────────────
        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t $USER_SERVICE_IMAGE:$IMAGE_TAG -f user-service/Dockerfile user-service/
                    docker build -t $ORDER_SERVICE_IMAGE:$IMAGE_TAG -f order-service/Dockerfile order-service/
                '''
            }
        }

        // ── TRIVY SCAN ───────────────────────────
        stage('Trivy Scan') {
            steps {
                sh '''
                    trivy image --severity HIGH,CRITICAL --exit-code 1 \
                        $USER_SERVICE_IMAGE:$IMAGE_TAG

                    trivy image --severity HIGH,CRITICAL --exit-code 1 \
                        $ORDER_SERVICE_IMAGE:$IMAGE_TAG
                '''
            }
        }

        // ── PUSH TO ECR ──────────────────────────
        stage('Push to ECR') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_REGION | \
                        docker login --username AWS --password-stdin $ECR_REGISTRY

                        docker push $USER_SERVICE_IMAGE:$IMAGE_TAG
                        docker push $ORDER_SERVICE_IMAGE:$IMAGE_TAG

                        docker tag \
                            ${USER_SERVICE_IMAGE}:${IMAGE_TAG} \
                            ${USER_SERVICE_IMAGE}:latest
                        docker tag \
                            ${ORDER_SERVICE_IMAGE}:${IMAGE_TAG} \
                            ${ORDER_SERVICE_IMAGE}:latest

                        docker push ${USER_SERVICE_IMAGE}:latest
                        docker push ${ORDER_SERVICE_IMAGE}:latest
                    '''
                }
            }
        }

        // ── DEPLOY TO EKS ────────────────────────
        stage('Deploy to EKS') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        aws eks update-kubeconfig \
                          --region $AWS_REGION \
                          --name $EKS_CLUSTER_NAME

                        export IMAGE_TAG=$IMAGE_TAG
                        export ECR_REGISTRY=$ECR_REGISTRY

                        envsubst < k8s/user-service/deployment.yaml | kubectl apply -f -
                        kubectl apply -f k8s/user-service/service.yaml

                        envsubst < k8s/order-service/deployment.yaml | kubectl apply -f -
                        kubectl apply -f k8s/order-service/service.yaml

                        kubectl apply -f k8s/alb-ingress/ingress.yaml
                    '''
                }
            }
        }

        // ── VERIFY ───────────────────────────────
        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl get pods -n cloudmart
                    kubectl get svc -n cloudmart
                    kubectl get ingress -n cloudmart
                '''
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'SUCCESS: CI/CD pipeline completed'
        }
        failure {
            echo 'FAILED: Check logs'
        }
    }
}