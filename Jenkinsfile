pipeline {
  agent any

  environment {
    REGISTRY   = "10.10.8.13"
    IMAGE_REPO = "demo/deneme-image"
    IMAGE_TAG  = "build-${BUILD_NUMBER}"
    IMAGE      = "${REGISTRY}/${IMAGE_REPO}:${IMAGE_TAG}"
    KANIKO_IMG = "gcr.io/kaniko-project/executor:v1.24.0-debug" // güncel ve debug imaj
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    // (opsiyonel) Docker'ı gerçekten kullanabiliyor muyuz?
    stage('Sanity: docker run check') {
      steps {
        sh '''bash -c '
          set -euo pipefail
          docker run --rm busybox:latest echo docker_ok
        ''''
      }
    }

    stage('Build & Push with Kaniko (container)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''bash -c '
            set -euo pipefail
            docker run --rm \
              -v "${WORKSPACE}:/workspace" \
              -e REGISTRY="${REGISTRY}" \
              -e IMAGE="${IMAGE}" \
              -e REG_USER="$REG_USER" \
              -e REG_PASS="$REG_PASS" \
              "${KANIKO_IMG}" /busybox/sh -c "
                set -e
                mkdir -p /kaniko/.docker
                AUTH=\\$(printf \\"%s:%s\\" \\"$REG_USER\\" \\"$REG_PASS\\" | base64 | tr -d '\\n')
                cat > /kaniko/.docker/config.json <<JSON
{ \\"auths\\": { \\"$REGISTRY\\": { \\"auth\\": \\"$AUTH\\" } } }
JSON
                /kaniko/executor \
                  --context=dir:///workspace \
                  --dockerfile=/workspace/Dockerfile \
                  --destination=\\"$IMAGE\\" \
                  --cache=true \
                  --verbosity=info \
                  --skip-tls-verify
              "
          ''''
        }
      }
    }
  }

  post {
    always {
      cleanWs(deleteDirs: true, notFailBuild: true)
    }
  }
}

