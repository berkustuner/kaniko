pipeline {
    agent any

    environment {
        IMAGE_NAME = "10.10.8.13/demo/deneme-image"
        TAG = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Build with Kaniko') {
            steps {
                dir("${env.WORKSPACE}") {
                    sh """
                        docker run --rm --network host \
                          -v /home/ubuntu/kaniko-example:/workspace \
                          -v /home/ubuntu/.docker:/kaniko/.docker \
                          gcr.io/kaniko-project/executor:latest \
                          --dockerfile=/workspace/Dockerfile \
                          --context=dir:///workspace \
                          --destination=${IMAGE_NAME}:${TAG} \
                          --insecure --insecure-pull --skip-tls-verify
                    """
                }
            }
        }

        stage('Deploy to Swarm') {
            steps {
                sh """
                    docker service update --force --with-registry-auth \
                      --image ${IMAGE_NAME}:${TAG} app_stack_web || \
                    docker service create --name app_stack_web --replicas 2 \
                      --publish 5000:5000 --network app_net \
                      --with-registry-auth ${IMAGE_NAME}:${TAG}
                """
            }
        }
    }
}

