pipeline {
  agent any

  environment {
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

    // Hostun container ağı kısıtlıysa bridge fail olur; host network ile deneriz.
    stage('Sanity: docker run check') {
      steps {
        sh '''bash -lc 'set -euo pipefail; docker run --rm --network host busybox:latest echo docker_ok''''
      }
    }

    stage('Build & Push with Kaniko') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''bash -lc "
            set -euo pipefail

            # Container içinde çalışacak scripti workspace'e yazıyoruz
            cat > ${WORKSPACE}/kaniko-run.sh <<'EOS'
#!/busybox/sh
set -e

# Harbor auth config
mkdir -p /kaniko/.docker
AUTH=$(printf '%s:%s' \"$REG_USER\" \"$REG_PASS\" | base64 | tr -d '\\n')
cat > /kaniko/.docker/config.json <<JSON
{ \"auths\": { \"$REGISTRY\": { \"auth\": \"$AUTH\" } } }
JSON

# Build & push
/kaniko/executor \
  --context=dir:///workspace \
  --dockerfile=/workspace/Dockerfile \
  --destination=\"$IMAGE\" \
  --cache=true \
  --verbosity=info \
  --skip-tls-verify
EOS

            chmod +x ${WORKSPACE}/kaniko-run.sh

            # Kaniko'yu host network ile koştur
            docker run --rm --network host \
              -v \"${WORKSPACE}:/workspace\" \
              -e REGISTRY=\"${REGISTRY}\" \
              -e IMAGE=\"${IMAGE}\" \
              -e REG_USER=\"${REG_USER}\" \
              -e REG_PASS=\"${REG_PASS}\" \
              ${KANIKO_IMG} /busybox/sh /workspace/kaniko-run.sh
          "'''
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

