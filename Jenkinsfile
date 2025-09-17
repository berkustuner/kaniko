pipeline {
  agent any

  environment {

    CONTEXT_HOST_PATH   = "/home/ubuntu/kaniko-example"
    HOST_DOCKER_CONFIG  = "/home/ubuntu/.docker"
    DOCKERFILE          = "Dockerfile"


    REGISTRY   = "10.10.8.13"
    IMAGE_REPO = "demo/deneme-image"
    IMAGE_NAME = "${REGISTRY}/${IMAGE_REPO}"
    TAG        = "build-${BUILD_NUMBER}"

    SECRET_NAME   = "pg_password"
    SECRET_TARGET = "pg_password"
    DB_PASS_FILE_PATH = "/run/secrets/pg_password"
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
          chmod +x ci/build_push.sh
          ./ci/build_push.sh
        '''
      }
    }

    stage('Deploy to Swarm') {
      steps {
        sh '''
          chmod +x ci/deploy.sh
          ./ci/deploy.sh "${IMAGE_NAME}:${TAG}"
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

