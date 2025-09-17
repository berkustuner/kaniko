pipeline {
  agent any

  environment {
    REGISTRY        = "10.10.8.13"
    IMAGE_REPO      = "demo/deneme-image"
    IMAGE_TAG       = "build-${BUILD_NUMBER}"
    IMAGE           = "${REGISTRY}/${IMAGE_REPO}:${IMAGE_TAG}"
    KANIKO_DIR      = "${WORKSPACE}/.kaniko"
    KANIKO_BIN      = "${KANIKO_DIR}/executor"
    KANIKO_VERSION  = "v1.12.0"
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Prepare Kaniko') {
      steps {
        sh '''
          set -euo pipefail
          mkdir -p "${KANIKO_DIR}"
          if [ ! -f "${KANIKO_BIN}" ]; then
            echo "Downloading Kaniko executor ${KANIKO_VERSION}..."
            curl -fsSL -o "${KANIKO_BIN}" "https://github.com/GoogleContainerTools/kaniko/releases/download/${KANIKO_VERSION}/executor"
            chmod +x "${KANIKO_BIN}"
          else
            echo "Kaniko executor already present"
          fi
        '''
      }
    }

    stage('Create Docker config for Kaniko') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''
            set -euo pipefail
            DOCKER_CONFIG_DIR="${KANIKO_DIR}/config"
            mkdir -p "${DOCKER_CONFIG_DIR}"
            AUTH="$(printf '%s:%s' "$REG_USER" "$REG_PASS" | base64 -w0)"
            cat > "${DOCKER_CONFIG_DIR}/config.json" <<EOF
{
  "auths": {
    "${REGISTRY}": {
      "auth": "${AUTH}"
    }
  }
}
EOF
            echo "Wrote docker config to ${DOCKER_CONFIG_DIR}/config.json"
          '''
        }
      }
    }

    stage('Build & Push with Kaniko') {
      steps {
        sh '''
          set -euo pipefail
          CONTEXT="dir://${WORKSPACE}"
          DOCKERFILE="${WORKSPACE}/Dockerfile"
          DOCKER_CONFIG_DIR="${KANIKO_DIR}/config"

          "${KANIKO_BIN}" \
            --context="${CONTEXT}" \
            --dockerfile="${DOCKERFILE}" \
            --destination="${IMAGE}" \
            --cache=true \
            --cache-dir="${KANIKO_DIR}/cache" \
            --verbosity=info \
            --docker-config="${DOCKER_CONFIG_DIR}" \
            --skip-tls-verify
        '''
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}

