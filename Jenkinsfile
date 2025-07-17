pipeline {
    agent any

    environment {
        IMAGE_NAME = "10.10.8.13/demo/deneme-image"
        TAG = "latest"
        DOCKER_CONFIG = "/kaniko/.docker"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "main", url: 'https://github.com/berkustuner/kaniko.git'
            }
        }

        stage('Confirm Files') {
            steps {
                sh "ls -la ${env.WORKSPACE}"
                sh "cat ${env.WORKSPACE}/Dockerfile"
            }
        }

        stage('Build with Kaniko') {
            steps {
                sh """
                    docker run --rm --network host \
                      -v ${env.WORKSPACE}:/workspace \
                      -v /var/jenkins_home/.docker/config.json:/kaniko/.docker/config.json \
                      gcr.io/kaniko-project/executor:latest \
                      --dockerfile=Dockerfile \
                      --context=dir:///workspace \
                      --destination=${env.IMAGE_NAME}:${env.TAG} \
                      --insecure --insecure-pull --skip-tls-verify
                """
            }
        }

        stage('Deploy to Swarm') {
            steps {
                sh """
                    docker service update --image ${env.IMAGE_NAME}:${env.TAG} app_stack_web || \
                    docker service create --name app_stack_web --replicas 2 --publish 5000:5000 \
                        --network app_net ${env.IMAGE_NAME}:${env.TAG}
                """
            }
        }
    }
}

