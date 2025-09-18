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

    // Sadece Docker'ı koşturabiliyor muyuz diye sanity check
    stage('Sanity: docker run check') {
      steps {
        sh(script: 'bash -lc "set -euo pipefail; docker run --rm --network host busybox:latest echo docker_ok"',
           label: 'docker run check')
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
		  '--destination=\\"${REGISTRY}/${IMAGE_REPO}:latest\\" ' +
		  // digest bilgisini dosyaya bırak:
                  '--image-name-with-digest-file=/workspace/image_ref.txt ' +
		  
                  '--cache=true --verbosity=info --skip-tls-verify"',
          label: 'kaniko build & push'
        )
	
	// Kaniko'nun bıraktığı image + digest referansını logla (artifakt istersen archiveArtifacts ekleyebiliriz)
        sh 'bash -lc "set -e; cat /home/ubuntu/kaniko-example/image_ref.txt || true"'
      }
    }
  }

  post {
    always {
      cleanWs(deleteDirs: true, notFailBuild: true)
    }
  }
    stage('Deploy (Docker Swarm)') {
      environment {
        SERVICE_NAME = "app_stack_web" // <- kendi servis adını yaz
        IMAGE_TAGGED = "10.10.8.13/demo/deneme-image:build-${BUILD_NUMBER}"
  }
      steps {
        sh(
          script: '''
    bash -lc 'set -euo pipefail;

      echo "Rolling update başlıyor: ${SERVICE_NAME} -> ${IMAGE_TAGGED}"

      # Servisi yeni imaj ile güncelle
      docker service update --with-registry-auth --image "${IMAGE_TAGGED}" "${SERVICE_NAME}"

      # Basit rollout kontrolü: Tüm task'lar running olana kadar bekle
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
''',
      label: 'swarm rollout'
    )
  }
}
 
}

