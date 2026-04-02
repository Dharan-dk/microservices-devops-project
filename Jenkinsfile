pipeline{
    agent any

    stages{
        stage('Checkout_SCM'){
            steps{
                echo "Checkout SCM"
                checkout scm
            }
        }
    }

    post{
        always{
            echo "This will always run"
        }
        success{
            echo "This will run only if the build is successful"
        }
        failure{
            echo "This will run only if the build fails"
        }
    }
}