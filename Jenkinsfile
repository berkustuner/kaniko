pipeline {
  agent any

  parameters {
    string(name: 'CONTEXT_HOST_PATH', defaultValue: '/home/ubuntu/kaniko-example',
           description: 'HOST üzerindeki build context dizini')
    string(name: 'HOST_DOCKER_CONFIG', defaultValue: '/home/ubuntu/.docker',
           description: 'HOST üzerindeki Docker config (auth) dizini')
    string(name: 'DOCKERFILE', defaultValue: 'Dockerfile',
           description: 'CONTEXT_HOST_PATH altında Dockerfile yolu')
  }

  environment {
    REGISTRY   = "10.10.8.13"
    IMAGE_REPO = "demo/deneme-image"
    IMAGE_NAME = "${REGISTRY}/${IMAGE_REPO}"
    TAG        = "build-${BUILD_NUMBER}"

    SECRET_NAME   = "pg_password"
    SECRET_TARGET = "pg_password"           // container içindeki dosya adı
    DB_PASS_FILE_PATH = "/run/secrets/pg_password"
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Docker Login (Harbor → Jenkins CLI)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''
            set -eu
            echo "$REG_PASS" | docker login "${REGISTRY}" -u "$REG_USER" --password-stdin
          '''
        }
      }
    }

    stage('Build & Push (Kaniko)') {
      steps {
        sh '''
          set -eu
          # host path kontrolleri
          docker run --rm -v "${CONTEXT_HOST_PATH}:/x:ro" alpine ls -la /x >/dev/null
          docker run --rm -v "${HOST_DOCKER_CONFIG}:/y:ro"  alpine ls -la /y >/dev/null

          docker run --rm --network host \
            -v "${CONTEXT_HOST_PATH}:/workspace" \
            -v "${HOST_DOCKER_CONFIG}:/kaniko/.docker:ro" \
            gcr.io/kaniko-project/executor:latest \
            --dockerfile="/workspace/${DOCKERFILE}" \
            --context=dir:///workspace \
            --destination="${IMAGE_NAME}:${TAG}" \
            --insecure --insecure-pull --skip-tls-verify
        '''
        echo "Pushed: ${IMAGE_NAME}:${TAG}"
      }
    }

    stage('Deploy to Swarm') {
      steps {
        sh '''
          set -eu

          # overlay ağ garanti
          docker network inspect app_net >/dev/null 2>&1 || docker network create --driver overlay app_net

          if docker service ls --format '{{.Name}}' | grep -w '^app_stack_web$' >/dev/null; then
            # secret idempotency: varsa önce kaldırıp sonra ekleyeceğiz
            if docker service inspect app_stack_web --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' | grep -q '"SecretName":"'"${SECRET_NAME}"'"'; then
              SECRET_ARGS="--secret-rm ${SECRET_TARGET} --secret-add source=${SECRET_NAME},target=${SECRET_TARGET}"
            else
              SECRET_ARGS="--secret-add source=${SECRET_NAME},target=${SECRET_TARGET}"
            fi

            # TEK update çağrısı, SERVIS ADI SONDA!
            docker service update \
              --with-registry-auth \
              --update-order stop-first \
              --update-parallelism 1 \
              --image "${IMAGE_NAME}:${TAG}" \
              --publish-rm 5000 \
              --publish-add mode=host,target=5000,published=5000 \
              --env-rm DB_PASS \
              --env-add DB_HOST=db_stack_db \
              --env-add DB_USER=postgres \
              --env-add DB_NAME=postgres \
              --env-add DB_PASS_FILE="${DB_PASS_FILE_PATH}" \
              ${SECRET_ARGS} \
              app_stack_web

          else
            docker service create --name app_stack_web --replicas 3 \
              --constraint 'node.labels.role_app==true' \
              --publish mode=host,target=5000,published=5000 \
              --network app_net \
              --with-registry-auth \
              --env DB_HOST=db_stack_db \
              --env DB_USER=postgres \
              --env DB_NAME=postgres \
              --env DB_PASS_FILE="${DB_PASS_FILE_PATH}" \
              --secret source=${SECRET_NAME},target=${SECRET_TARGET} \
              "${IMAGE_NAME}:${TAG}"
          fi
        '''
      }
    }
  }

  post {
    always {
      sh '''
        set -e
        docker logout "${REGISTRY}" || true
      '''
      // cleanWs() yerine plugin gerektirmeyen:
      deleteDir()
    }
  }
}

