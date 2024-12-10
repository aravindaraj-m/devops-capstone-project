pipeline {
    agent any

    stages {
        stage('Build a Docker Image and Push the image to Docker Hub') {
            steps {
<<<<<<< HEAD
                withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                    sh './build.sh'
=======
                script {
                    withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                    sh """
                    chmod +x build.sh
                    ./build.sh $BUILD_NUMBER
                    """
>>>>>>> dev
                    }
                }
            }
        }
        stage('Deploy') {
            steps {
                script {
<<<<<<< HEAD
                    withCredentials([
                        string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN'),
                        sshUserPrivateKey(credentialsId: 'devops-project-key', keyFileVariable: 'PEM_FILE')
                    ]) {
                        sh './deploy.sh'
=======
                    withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                        sh """
                        chmod +x deploy.sh
                        ./deploy.sh
                        """
>>>>>>> dev
                    }
                }
            }
        }
<<<<<<< HEAD
=======
    }
>>>>>>> dev
}