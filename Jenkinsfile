pipeline {
    agent any

    environment {
        IMAGE_NAME = "10.10.8.13/demo/deneme-image"
        TAG = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Build with Kaniko') {
            steps {
                dir("${env.WORKSPACE}") {
                    sh """
                        docker run --rm --network host \
                          -v /home/ubuntu/kaniko-example:/workspace \
                          -v /home/ubuntu/.docker:/kaniko/.docker \
                          gcr.io/kaniko-project/executor:latest \
                          --dockerfile=/workspace/Dockerfile \
                          --context=dir:///workspace \
                          --destination=${IMAGE_NAME}:${TAG} \
                          --insecure --insecure-pull --skip-tls-verify
                    """
                }
            }
        }
	stage('Deploy to Swarm') {
	    steps {
  		sh '''
    		    set -e
    		    TAG=build-${BUILD_NUMBER}-${GIT_COMMIT::7}

    		    # Roll-update – önce eski task’ı durdur, sonra yenisini başlat
     		    docker service update \
      		    --image 10.10.8.13/demo/deneme-image:${TAG} \
      		    --update-parallelism 1 \
      		    --update-order stop-first \
      		    --with-registry-auth \
      		    --force \
      		    app_stack_web
  		'''
		}
	      }

    }
}

