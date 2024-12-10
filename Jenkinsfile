pipeline {
    agent any

    stages {
        stage('Build a Docker Image and Push the image to Docker Hub') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                    sh """
                    chmod +x build.sh
                    ./build.sh $BUILD_NUMBER
                    """
                    }
                }
            }
        }
        stage('Deploy') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                        sh """
                        chmod +x deploy.sh
                        ./deploy.sh
                        """
                    }
                }
            }
        }

    }
}