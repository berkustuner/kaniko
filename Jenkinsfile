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
    SECRET_TARGET = "pg_password"
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

          docker network inspect app_net >/dev/null 2>&1 || docker network create --driver overlay app_net

          if docker service ls --format '{{.Name}}' | grep -w '^app_stack_web$' >/dev/null; then
            # pg_password secret idempotency
            if docker service inspect app_stack_web --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' | grep -q '"SecretName":"'"${SECRET_NAME}"'"'; then
              SECRET_ARGS="--secret-rm ${SECRET_TARGET} --secret-add source=${SECRET_NAME},target=${SECRET_TARGET}"
            else
              SECRET_ARGS="--secret-add source=${SECRET_NAME},target=${SECRET_TARGET}"
            fi

            # jwt_secret idempotency
            if docker service inspect app_stack_web --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' | grep -q '"SecretName":"jwt_secret"'; then
              JWT_SECRET_ARGS=""
            else
              JWT_SECRET_ARGS="--secret-add source=jwt_secret,target=jwt_secret"
            fi

            # app_user idempotency
            if docker service inspect app_stack_web --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' | grep -q '"SecretName":"app_user"'; then
              APP_USER_ARGS=""
            else
              APP_USER_ARGS="--secret-add source=app_user,target=app_user"
            fi

            # app_pass idempotency
            if docker service inspect app_stack_web --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' | grep -q '"SecretName":"app_pass"'; then
              APP_PASS_ARGS=""
            else
              APP_PASS_ARGS="--secret-add source=app_pass,target=app_pass"
            fi

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
              ${JWT_SECRET_ARGS} \
              ${APP_USER_ARGS} \
              ${APP_PASS_ARGS} \
              --env-add JWT_SECRET_FILE=/run/secrets/jwt_secret \
              --env-add APP_USER_FILE=/run/secrets/app_user \
              --env-add APP_PASS_FILE=/run/secrets/app_pass \
              app_stack_web

          else
            docker service create --name app_stack_web --replicas 3 \
              --constraint 'node.labels.role_app==true' \
              --publish mode=host,target=5000,published=5000 \
              --network app_net \
              --with-registry-auth \
              --env JWT_SECRET_FILE=/run/secrets/jwt_secret \
              --secret source=jwt_secret,target=jwt_secret \
              --secret source=app_user,target=app_user \
              --secret source=app_pass,target=app_pass \
              --env APP_USER_FILE=/run/secrets/app_user \
              --env APP_PASS_FILE=/run/secrets/app_pass \
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
      deleteDir()
    }
  }
}
