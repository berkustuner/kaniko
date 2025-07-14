pipeline {
    agent any

    environment {
        IMAGE_NAME = "10.10.8.13/demo/deneme-image"
        TAG = "latest"
        DOCKER_CONFIG = "/kaniko/.docker/" // Kaniko container içinde default yol
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/berkustuner/kaniko.git' // <-- gerekirse güncelle
            }
        }

        stage('Build with Kaniko') {
            steps {
                sh '''
                docker run --rm -v $(pwd):/workspace \
                  -v $HOME/.docker:/kaniko/.docker \
                  gcr.io/kaniko-project/executor:latest \
                  --dockerfile=Dockerfile \
                  --context=dir:///workspace \
                  --destination=$IMAGE_NAME:$TAG \
                  --insecure --insecure-pull --skip-tls-verify
                '''
            }
        }

        stage('Deploy to Swarm') {
            steps {
                sh '''
                docker service update --image $IMAGE_NAME:$TAG app-stack_web || \
                docker service create --name app-stack_web --replicas 2 --publish 5000:5000 \
                    --network app_net $IMAGE_NAME:$TAG
                '''
            }
        }
    }
}

