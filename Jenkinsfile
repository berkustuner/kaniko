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

    stage('Sanity: docker run check') {
      steps {
        sh(script: 'bash -lc "set -euo pipefail; docker run --rm --network host busybox:latest echo docker_ok"', label: 'docker run check')
      }
    }

    stage('Build & Push with Kaniko') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {

          // 1) Harbor auth dosyasını hostta oluştur (sonra /kaniko/.docker olarak mount edeceğiz)
          sh(
            script: 'bash -lc "set -euo pipefail; ' +
                    'DOCKER_CONFIG_DIR=\\"${WORKSPACE}/.kaniko-docker\\"; ' +
                    'mkdir -p \\"$DOCKER_CONFIG_DIR\\"; ' +
                    'AUTH=$(printf \\"%s:%s\\" \\"$REG_USER\\" \\"$REG_PASS\\" | base64 | tr -d \\"\\\\n\\"); ' +
                    'printf \\"{\\\\\\"auths\\\\\\":{\\\\\\"%s\\\\\\":{\\\\\\"auth\\\\\\":\\\\\\"%s\\\\\\"}}}\\" \\"${REGISTRY}\\" \\"$AUTH\\" > \\"$DOCKER_CONFIG_DIR/config.json\\""',
            label: 'write docker config'
          )

          // 2) Kaniko container ile build & push
          sh(
            script: 'bash -lc "set -euo pipefail; ' +
                    'docker run --rm --network host ' +
                    '-v \\"${WORKSPACE}:/workspace\\" ' +
                    '-v \\"${WORKSPACE}/.kaniko-docker:/kaniko/.docker\\" ' +
                    '${KANIKO_IMG} /kaniko/executor ' +
                    '--context=dir:///workspace ' +
                    '--dockerfile=/workspace/Dockerfile ' +
                    '--destination=\\"${IMAGE}\\" ' +
                    '--cache=true --verbosity=info --skip-tls-verify"',
            label: 'kaniko build & push'
          )
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

