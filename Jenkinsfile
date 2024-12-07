pipeline {
    agent any

    stages {
        stage('Build a Docker Image and Push the image to Docker Hub') {
            steps {
                withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                    sh '''
                    chmod +x build.sh
                    ./build.sh
                    '''
                    }
                }
            }
        stage('Deploy') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN'),
                        sshUserPrivateKey(credentialsId: 'devops-project-key', keyFileVariable: 'PEM_KEY')
                    ]) {
                        sh '''
                        chmod +x deploy.sh
                        ./deploy.sh
                        '''
                    }
                }
            }
        }
    }
}