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
          script {
            // 1) Docker config dizini
            def dockerConfigDir = "${env.WORKSPACE}/.kaniko-docker"
            sh 'bash -lc "set -euo pipefail; mkdir -p \\"' + dockerConfigDir + '\\""'

            // 2) AUTH (Groovy tarafında base64)
            def auth = java.util.Base64.getEncoder()
              .encodeToString("${env.REG_USER}:${env.REG_PASS}".getBytes("UTF-8"))

            // 3) config.json yaz
            def cfg = """{
  "auths": { "${env.REGISTRY}": { "auth": "${auth}" } }
}"""
            writeFile file: "${dockerConfigDir}/config.json", text: cfg
          }

          // 4) Kaniko build & push (DIKKAT: /kaniko/executor YOK!)
          sh(
            script: 'bash -lc "set -euo pipefail; ' +
                    'docker run --rm --network host ' +
                    '-v \\"${WORKSPACE}:/workspace\\" ' +
                    '-v \\"${WORKSPACE}/.kaniko-docker:/kaniko/.docker\\" ' +
                    '${KANIKO_IMG} ' + // ENTRYPOINT already /kaniko/executor
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

