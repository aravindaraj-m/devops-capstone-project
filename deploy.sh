#!/bin/bash

# Configuration file
DEPLOY_CONFIG_FILE="./configurations/config.txt"

# Check if the config file exists
if [ ! -f "$DEPLOY_CONFIG_FILE" ]; then
  echo "Error: Configuration file $DEPLOY_CONFIG_FILE not found!"
  exit 1
fi

# Load variables from the config file
echo "Loading configuration from $DEPLOY_CONFIG_FILE..."
source "$DEPLOY_CONFIG_FILE"

# Check required variables
REQUIRED_VARS=("EC2_USER" "EC2_HOST" "DOCKER_COMPOSE_FILE" "NGINX_CONF" "PROM_YML" "REMOTE_DIR" "DOCKER_USERNAME")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: Required variable $var is not set in $DEPLOY_CONFIG_FILE!"
    exit 1
  else
    echo "$var = ${!var}"
  fi
done

EC2_INSTANCE="$EC2_USER:$EC2_HOST"
echo "$EC2_INSTANCE"

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

#deployement on EC2 Instance
echo "Deploying to EC2 Instance - !@!$EC2_INSTANCE!@!"

#login to EC2 Instance to stop running container and do clean up of old deployment files
ssh -i "$PEM_FILE" "$EC2_USER@$EC2_HOST" << EOF
  echo "Stopping and Deleting all the running Docker containers."
  sudo docker ps -q | xargs -r docker stop
  sudo docker ps -aq | xargs -r docker rm
  echo "Deleting all Docker Images."
  sudo docker images -q | xargs -r docker rmi
  echo "Cleaning up old files in $REMOTE_DIR."
  sudo rm -rf $REMOTE_DIR
  echo "Recreating the directory $REMOTE_DIR."
  mkdir -p $REMOTE_DIR
  chmod 755 $REMOTE_DIR
EOF

#copying the docker-compose and its dependent files to EC2 Instance
echo "Copying Docker-compose and its dependencies to EC2 deployment directory."
scp -i "$PEM_FILE" $DOCKER_COMPOSE_FILE "$EC2_USER@$EC2_HOST:$REMOTE_DIR"
scp -i "$PEM_FILE" -r ./dependencies/ "$EC2_USER@$EC2_HOST:$REMOTE_DIR"
echo "copied Docker-compose.yml and its dependencies in $REMOTE_DIR"

#execute docker-compose.yml file in EC2 Instance
echo "Starting Deployment in EC2 instance at $EC2_HOST."
ssh -i "$PEM_FILE" "$EC2_USER@$EC2_HOST" << EOF
  echo "Changing to $REMOTE_DIR directory."
  cd $REMOTE_DIR
  echo "Login to Docker Hub"
  cat "$DOCKERHUB_TOKEN" | docker login -username "$DOCKER_USERNAME" --password-stdin
  if [ $? -ne 0 ]; then
    echo "Error: Docker login failed!"
    exit 1
  fi
  echo "Running Docker compose to start container"
  sudo docker-compose up -d
  echo "Deployment completed Successfully in $EC2_HOST!"
  sleep 3
  echo "!@!  All Docker Images  !@!"
  sudo docker images
  echo "!@!  All Running Docker Containers  !@!"
  sudo docker ps -a
  echo "Logout from Docker Hub"
  sudo docker logout
EOF

# #scp -i "$PEM_FILE" docker-compose.yml "$EC2_USER@$EC2_HOST:/home/$EC2_USER/" --> remove {-i "$PEM_FILE"} to use jenkins global credentials
# #ssh -i "$PEM_FILE" "$EC2_USER@$EC2_HOST" --> remove {-i "$PEM_FILE"} to use jenkins global credentials