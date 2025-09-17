pipeline {
  agent {
    docker {
      image 'gcr.io/kaniko-project/executor:latest'
      args  '-v /home/ubuntu/kaniko-example:/workspace -v /home/ubuntu/.docker:/kaniko/.docker:ro'
    }
  }

  environment {
    REGISTRY   = "10.10.8.13"
    IMAGE_REPO = "demo/deneme-image"
    IMAGE_NAME = "${REGISTRY}/${IMAGE_REPO}"
    TAG        = "build-${BUILD_NUMBER}"
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Push (Kaniko)') {
      steps {
        sh '''
          /kaniko/executor \
            --dockerfile=/workspace/Dockerfile \
            --context=dir:///workspace \
            --destination="${IMAGE_NAME}:${TAG}" \
            --insecure --insecure-pull --skip-tls-verify
          echo "Pushed: ${IMAGE_NAME}:${TAG}"
        '''
      }
    }

    stage('Deploy to Swarm (Update Only)') {
      steps {
        sh '''
          set -eu
          docker network inspect app_net >/dev/null 2>&1 || docker network create --driver overlay app_net

          docker service update \
            --with-registry-auth \
            --update-order stop-first \
            --update-parallelism 1 \
            --image "${IMAGE_NAME}:${TAG}" \
            app_stack_web
        '''
      }
    }
  }

  post {
    always {
      deleteDir()
    }
  }
}

