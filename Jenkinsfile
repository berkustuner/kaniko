pipeline {
    agent any

    environment {
        IMAGE_NAME = "10.10.8.13/demo/deneme-image"
        TAG = "latest"
    }

    stages {
        stage('Prepare Code') {
            steps {
                sh 'cp -r /var/jenkins_home/kaniko-code/* .'
            }
        }

        stage('Confirm Files') {
            steps {
                sh "ls -la"
                sh "cat Dockerfile"
            }
        }

        stage('Build with Kaniko') {
            steps {
                sh """
                    docker run --rm --network host \
                      -v \$(pwd):/workspace \
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

