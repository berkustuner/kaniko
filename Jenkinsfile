pipeline {
  agent any

  environment {
    REGISTRY       = '10.10.8.13'
    IMAGE          = "${REGISTRY}/demo/deneme-image"
    DOCKER_CONFIG  = "${env.HOME}/.docker"      // Kaniko auth
  }

  stages {
    stage('Checkout SCM') {
      steps { checkout scm }
    }

    stage('Build & Push (Kaniko)') {
      steps {
        script {
          TAG     = "build-${env.BUILD_NUMBER}-" +
                    sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.TAG = TAG                      // sonraki adımlar için ortam değişkeni
        }

        sh '''
          #!/usr/bin/env bash
          set -euo pipefail

          docker run --rm --network host \
            -v "$WORKSPACE":/workspace \
            -v "$DOCKER_CONFIG":/kaniko/.docker \
            gcr.io/kaniko-project/executor:latest \
            --dockerfile=/workspace/Dockerfile \
            --context=dir:///workspace \
            --destination=${IMAGE}:${TAG} \
            --insecure --skip-tls-verify --insecure-pull
        '''
      }
    }

    stage('Deploy to Swarm') {
      steps {
        sh '''
          #!/usr/bin/env bash
          set -euo pipefail

          if docker service ls --filter name=app_stack_web --format '{{.Name}}' | grep -qw app_stack_web; then
            echo "🔄  Servis var, update ediliyor…"
            docker service update \
              --image ${IMAGE}:${TAG} \
              --update-parallelism 1 \
              --update-order stop-first \
              --with-registry-auth \
              --force \
              app_stack_web
          else
            echo "🆕  Servis yok, create ediliyor…"
            docker service create \
              --name app_stack_web \
              --replicas 2 \
              --publish 5000:5000 \
              --network app_net \
              --with-registry-auth \
              ${IMAGE}:${TAG}
          fi
        '''
      }
    }
  }

  post {
    failure {
      echo '⚠️  Deploy başarısız, rollback deneniyor…'
      sh '''
        #!/usr/bin/env bash
        if docker service inspect app_stack_web >/dev/null 2>&1; then
          docker service rollback app_stack_web || true
        else
          echo "⏩  Rollback atlanıyor; servis hiç oluşmamış."
        fi
      '''
    }
  }
}

