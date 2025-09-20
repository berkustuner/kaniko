pipeline {
  agent any

  environment {
    REGISTRY      = "10.10.8.13"
    IMAGE_REPO    = "demo/deneme-image"
    IMAGE_TAG     = "build-${BUILD_NUMBER}"
    IMAGE         = "${REGISTRY}/${IMAGE_REPO}:${IMAGE_TAG}"
    IMAGE_LATEST  = "${REGISTRY}/${IMAGE_REPO}:latest"

    CONTEXT_HOST_PATH  = "${WORKSPACE}"   // artık checkout edilen repo
    HOST_DOCKER_CONFIG = "/home/ubuntu/.docker"
    DOCKERFILE = "Dockerfile"

    SERVICE_NAME = "app_stack_web"
    KANIKO_IMG   = "gcr.io/kaniko-project/executor:v1.24.0-debug"
  }

  options { timestamps() }

  stages {
    stage('Sanity: docker run check') {
      steps {
        sh 'bash -lc "set -euo pipefail; docker run --rm --network host busybox:latest echo docker_ok"'
      }
    }

    stage('Verify context & Dockerfile') {
      steps {
        sh 'bash -lc "set -e; ls -la "${CONTEXT_HOST_PATH}"; echo "${WORKSPACE}"; test -f "${CONTEXT_HOST_PATH}/Dockerfile""'
      }
    }

    stage('Build & Push with Kaniko') {
      steps {
        sh '''
          bash -lc "
            set -euo pipefail
            docker run --rm --network host \
              -v "${CONTEXT_HOST_PATH}:/workspace" \
              -v "${HOST_DOCKER_CONFIG}:/kaniko/.docker:ro" \
              "${KANIKO_IMG}" \
		--context=dir:///workspace \
                --dockerfile="${WORKSPACE}/${DOCKERFILE}" \
                --destination="${IMAGE}" \
                --destination="${IMAGE_LATEST}" \
                --cache=true --verbosity=info --skip-tls-verify
          "
        '''
      }
    }

    stage('Rolling Update (image only)') {
      steps {
        sh '''
          bash -lc "
            set -euo pipefail
            docker service update \
              --with-registry-auth \
              --update-order stop-first \
              --update-parallelism 1 \
              --update-delay 5s \
              --image \\"${IMAGE}\\" \
              \\"${SERVICE_NAME}\\"
          "
        '''
      }
    }
  }

  post {
    always {
      cleanWs(deleteDirs: true, notFailBuild: true)
    }
  }
}

