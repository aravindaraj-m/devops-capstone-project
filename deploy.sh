#!/bin/bash

# Configuration file
DEPLOY_CONFIG_FILE="./configurations/config.ini"

# Check if the config file exists
if [ ! -f "$DEPLOY_CONFIG_FILE" ]; then
  echo "Error: Configuration file $DEPLOY_CONFIG_FILE not found!"
  exit 1
fi

# Load variables from the config file
echo "Loading configuration from $DEPLOY_CONFIG_FILE..."
source "$DEPLOY_CONFIG_FILE"

# Check required variables
REQUIRED_VARS=("DOCKER_COMPOSE_FILE" "NGINX_CONF" "PROM_YML" "IMAGE_TAG" "ALERT_RULES" "ALERT_MANAGER" "DOCKER_USERNAME" "DOCKER_DEV_REPO" "DOCKER_PROD_REPO")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: Required variable $var is not set in $DEPLOY_CONFIG_FILE!"
    exit 1
  else
    echo "$var = ${!var}"
  fi
done

# EC2_INSTANCE="$EC2_USER:$EC2_HOST"
# echo "$EC2_INSTANCE"

#check if docker-compose.yml file exists
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
  echo "Error: $DOCKER_COMPOSE_FILE not found!"
  exit 1
fi

#check if nginx.conf file exists
if [ ! -f "$NGINX_CONF" ]; then
  echo "Error: $NGINX_CONF not found!"
  exit 1
fi

#check if prometheus.yml file exists
if [ ! -f "$PROM_YML" ]; then
  echo "Error: $PROM_YML not found!"
  exit 1
fi

#check pem file exists
if [ ! -f "$ALERT_RULES" ]; then
  echo "Error: $ALERT_RULES not found!"
  exit 1
fi

#check docker credentials file exists
if [ ! -f "$ALERT_MANAGER" ]; then
  echo "Error: $ALERT_MANAGER not found!"
  exit 1
fi

DEV_IMAGE="$DOCKER_USERNAME/$DOCKER_DEV_REPO:$IMAGE_TAG"
PROD_IMAGE="$DOCKER_USERNAME/$DOCKER_PROD_REPO:$IMAGE_TAG"

echo "This Development repository Docker Image name --> $DEV_IMAGE"
echo "This Production Repository Image name --> $PROD_IMAGE"

echo "All current docker images"
docker images

echo "Retag Dev Repo Docker Image to Prod Repo Dockker Image"
docker tag "$DEV_IMAGE" "$PROD_IMAGE"

echo "Login to Docker Hub"
echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKER_USERNAME" --password-stdin
if [ $? -ne 0 ]; then
  echo "Error: Docker login failed!"
  exit 1
fi
echo "Push Prod Image to Docker Repo"
docker push "$PROD_IMAGE"
sleep 5
#using DOCKER_IMAGE as variable to send image name and tag as arugument to docker-compose file 
echo "Running Docker compose from production image to start container"
DOCKER_IMAGE="$DOCKER_USERNAME/$DOCKER_PROD_REPO:$IMAGE_TAG" docker-compose up -d
echo "Deployment completed Successfully in $EC2_HOST!"
sleep 3
echo "!@!  All Docker Images  !@!"
docker images
echo "!@!  All Running Docker Containers  !@!"
docker ps -a
echo "Logout from Docker Hub"
docker logout

#deployement on EC2 Instance
# echo "Deploying to EC2 Instance - !@!$EC2_INSTANCE!@!"

#login to EC2 Instance to stop running container and do clean up of old deployment files
# ssh -i "$PEM_KEY" "$EC2_USER@$EC2_HOST" << EOF
#   echo "Stopping and Deleting all the running Docker containers."
#   docker ps -q | xargs -r docker stop
#   docker ps -aq | xargs -r docker rm
#   docker ps -a
#   echo "Deleting all Docker Images."
#   docker images -q | xargs -r docker rmi -f
#   sleep 3
#   docker images
#   echo "Cleaning up old files in $REMOTE_DIR."
#   rm -rf $REMOTE_DIR
#   echo "Recreating the directory $REMOTE_DIR."
#   mkdir -p $REMOTE_DIR
#   chmod 755 $REMOTE_DIR
# EOF

#copying the docker-compose and its dependent files to EC2 Instance
# echo "Copying Docker-compose and its dependencies to EC2 deployment directory."
# scp -i "$PEM_KEY" $DOCKER_COMPOSE_FILE "$EC2_USER@$EC2_HOST:$REMOTE_DIR"
# scp -i "$PEM_KEY" -r ./dependencies/ "$EC2_USER@$EC2_HOST:$REMOTE_DIR"
# echo "copied Docker-compose.yml and its dependencies in $REMOTE_DIR"

#execute docker-compose.yml file in EC2 Instance
# echo "Starting Deployment in EC2 instance at $EC2_HOST."
# ssh -i "$PEM_KEY" "$EC2_USER@$EC2_HOST" << EOF
#   echo "Changing to $REMOTE_DIR directory."
#   cd $REMOTE_DIR
#   cat "$DOCKERHUB_TOKEN" | docker login -u "$DOCKER_USERNAME" --password-stdin
#   if [ $? -ne 0 ]; then
#     echo "Error: Docker login failed!"
#     exit 1
#   fi
#   echo "Docker Image pull form dev repe"
#   docker pull "$DEV_IMAGE"
#   echo "Retag Dev Image to Prod Image"
#   docker tag "$DEV_IMAGE" "$PROD_IMAGE"
#   echo "Login to Docker Hub"
#   echo "Push Prod Image to Docker Repo"
#   docker push "$PROD_IMAGE"
#   sleep 5
#   #using DOCKER_IMAGE as variable to send image name and tag as arugument to docker-compose file 
#   echo "Running Docker compose from production image to start container"
#   DOCKER_IMAGE="$DOCKER_USERNAME/$DOCKER_PROD_REPO:$IMAGE_TAG" docker-compose up -d
#   echo "Deployment completed Successfully in $EC2_HOST!"
#   sleep 3
#   echo "!@!  All Docker Images  !@!"
#   docker images
#   echo "!@!  All Running Docker Containers  !@!"
#   docker ps -a
#   echo "Logout from Docker Hub"
#   docker logout
# EOF