pipeline {
  agent any

  environment {
    REGISTRY        = "10.10.8.13"
    KANIKO_DIR      = "${WORKSPACE}/.kaniko"
    KANIKO_BIN      = "${KANIKO_DIR}/executor"
    KANIKO_VERSION  = "v1.12.0"
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Prepare Kaniko') {
      steps {
        sh '''bash -c "
          set -euo pipefail
          mkdir -p \\"${KANIKO_DIR}\\"
          if [ ! -f \\"${KANIKO_BIN}\\" ]; then
            echo \\"Downloading Kaniko executor ${KANIKO_VERSION}...\\"
            curl -fsSL -o \\"${KANIKO_BIN}\\" \\"https://github.com/GoogleContainerTools/kaniko/releases/download/${KANIKO_VERSION}/executor_linux_amd64\\"
            chmod +x \\"${KANIKO_BIN}\\"
          else
            echo \\"Kaniko executor already present\\"
          fi
        "'''
      }
    }

    stage('Test Docker Config') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''bash -c "
            set -euo pipefail
            DOCKER_CONFIG_DIR=\\"${KANIKO_DIR}/config\\"
            mkdir -p \\"${DOCKER_CONFIG_DIR}\\"
            AUTH=$(printf '%s:%s' \\"$REG_USER\\" \\"$REG_PASS\\" | base64 | tr -d '\\n')
            cat > \\"${DOCKER_CONFIG_DIR}/config.json\\" <<EOF
{
  \\"auths\\": {
    \\"${REGISTRY}\\": {
      \\"auth\\": \\"${AUTH}\\"
    }
  }
}
EOF
            echo \\"✅ Docker config created at ${DOCKER_CONFIG_DIR}/config.json\\"
            echo \\"hello kaniko\\"
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

