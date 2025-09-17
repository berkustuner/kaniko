pipeline {
  agent any

  environment {
    CONTEXT_HOST_PATH  = "/home/ubuntu/kaniko-example"
    HOST_DOCKER_CONFIG = "/home/ubuntu/.docker"
    DOCKERFILE         = "Dockerfile"

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

    stage('Docker Login (Harbor → Jenkins CLI)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''
            set -eu
            echo "$REG_PASS" | docker login "${REGISTRY}" -u "$REG_USER" --password-stdin
          '''
        }
      }
    }

    stage('Build & Push (Kaniko)') {
      steps {
        sh '''
          set -eu
          # host path kontrolleri
          docker run --rm -v "${CONTEXT_HOST_PATH}:/x:ro" alpine ls -la /x >/dev/null
          docker run --rm -v "${HOST_DOCKER_CONFIG}:/y:ro"  alpine ls -la /y >/dev/null

          docker run --rm --network host \
            -v "${CONTEXT_HOST_PATH}:/workspace" \
            -v "${HOST_DOCKER_CONFIG}:/kaniko/.docker:ro" \
            gcr.io/kaniko-project/executor:latest \
            --dockerfile="/workspace/${DOCKERFILE}" \
            --context=dir:///workspace \
            --destination="${IMAGE_NAME}:${TAG}" \
            --insecure --insecure-pull --skip-tls-verify
        '''
        echo "Pushed: ${IMAGE_NAME}:${TAG}"
      }
    }

    stage('Deploy to Swarm (Update Only)') {
      steps {
        sh '''
          set -eu

          # overlay network garanti
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
      sh '''
        set -e
        docker logout "${REGISTRY}" || true
      '''
      deleteDir()
    }
  }
}

