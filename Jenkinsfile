pipeline {
  agent any

  environment {
    // HOST üstündeki path'ler (hard-coded)
    CONTEXT_HOST_PATH = "/home/ubuntu/kaniko-example"
    HOST_DOCKER_CONFIG = "/home/ubuntu/.docker"
    DOCKERFILE = "Dockerfile"

    // Registry & image bilgileri (hard-coded)
    REGISTRY   = "10.10.8.13"
    IMAGE_REPO = "demo/deneme-image"
    IMAGE_TAG  = "build-${BUILD_NUMBER}"
    IMAGE      = "${REGISTRY}/${IMAGE_REPO}:${IMAGE_TAG}"

    // Kaniko imajı
    KANIKO_IMG = "gcr.io/kaniko-project/executor:v1.24.0-debug"
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Sanity: docker run check') {
      steps {
        sh(script: 'bash -lc "set -euo pipefail; docker run --rm --network host busybox:latest echo docker_ok"',
           label: 'docker run check')
        sh(script: 'bash -lc "set -e; ls -la \\"${CONTEXT_HOST_PATH}\\"; test -f \\"${CONTEXT_HOST_PATH}/${DOCKERFILE}\\""',
           label: 'verify context & Dockerfile')
      }
    }

    stage('Build & Push with Kaniko') {
      steps {
        sh(
          script: 'bash -lc "set -euo pipefail; ' +
                  'docker run --rm --network host ' +
                  '-v \\"${CONTEXT_HOST_PATH}:/workspace\\" ' +
                  '-v \\"${HOST_DOCKER_CONFIG}:/kaniko/.docker:ro\\" ' +
                  '${KANIKO_IMG} ' +
                  '--context=dir:///workspace ' +
                  '--dockerfile=\\"${DOCKERFILE}\\" ' +
                  '--destination=\\"${IMAGE}\\" ' +
                  '--cache=true --verbosity=info --skip-tls-verify"',
          label: 'kaniko build & push'
        )
      }
    }
  }

  post {
    always {
      cleanWs(deleteDirs: true, notFailBuild: true)
    }
  }
}

