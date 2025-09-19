pipeline {
  agent any

  environment {
    CONTEXT_HOST_PATH = "/home/ubuntu/kaniko-example"
    HOST_DOCKER_CONFIG = "/home/ubuntu/.docker"
    DOCKERFILE = "Dockerfile"

    REGISTRY   = "10.10.8.13"
    IMAGE_REPO = "demo/deneme-image"
    IMAGE_TAG  = "build-${BUILD_NUMBER}"
    IMAGE      = "${REGISTRY}/${IMAGE_REPO}:${IMAGE_TAG}"

    KANIKO_IMG = "gcr.io/kaniko-project/executor:v1.24.0-debug"
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Sanity: docker run check') {
      steps {
        sh 'bash -lc "set -euo pipefail; docker run --rm --network host busybox:latest echo docker_ok"'
      }
    }

    stage('Build & Push with Kaniko') {
      steps {
        sh '''
          bash -lc "set -euo pipefail;
            docker run --rm --network host \
              -v \\"${CONTEXT_HOST_PATH}:/workspace\\" \
              -v \\"${HOST_DOCKER_CONFIG}:/kaniko/.docker:ro\\" \
              ${KANIKO_IMG} \
              --context=dir:///workspace \
              --dockerfile=\\"${DOCKERFILE}\\" \
              --destination=\\"${IMAGE}\\" \
              --destination=\\"${REGISTRY}/${IMAGE_REPO}:latest\\" \
              --image-name-with-digest-file=/workspace/image_ref.txt \
              --cache=true --verbosity=info --skip-tls-verify"
        '''
        sh 'cat /home/ubuntu/kaniko-example/image_ref.txt || true'
      }
    }

    stage('Deploy (Docker Swarm)') {
      environment {
        SERVICE_NAME = "app_stack_web"
        IMAGE_TAGGED = "10.10.8.13/demo/deneme-image:build-${BUILD_NUMBER}"
      }
      steps {
        sh '''
          bash -lc 'set -euo pipefail;

          echo "Rolling update başlıyor: ${SERVICE_NAME} -> ${IMAGE_TAGGED}"
	  
	  docker service update --update-order stop-first --update-parallelism 1 "${SERVICE_NAME}"          

          docker service update --with-registry-auth --image "${IMAGE_TAGGED}" "${SERVICE_NAME}"

          for i in $(seq 1 60); do
            RUNNING=$(docker service ps --format "{{.DesiredState}} {{.CurrentState}}" "${SERVICE_NAME}" | grep -c "^Running")
            TOTAL=$(docker service ps --format "{{.ID}}" "${SERVICE_NAME}" | wc -l)
            if [ "$RUNNING" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
              echo "✅ Rollout tamam: ${RUNNING}/${TOTAL}"
              exit 0
            fi
            echo "Bekleniyor ($i/60): ${RUNNING}/${TOTAL} task running..."
            sleep 2
          done

          echo "❌ Rollout timeout oldu."
          docker service ps "${SERVICE_NAME}"
          exit 1
          '
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

