#!/bin/bash

# Exit on any error
set -e

# Configuration file
BUILD_CONFIG_FILE="./configurations/config.ini"

# Check if the config file exists
if [ ! -f "$BUILD_CONFIG_FILE" ]; then
  echo "Error: Configuration file $BUILD_CONFIG_FILE not found!"
  exit 1
fi

# Load variables from the config file
echo "Loading configuration from $BUILD_CONFIG_FILE..."
source "$BUILD_CONFIG_FILE"

# Check required variables
REQUIRED_VARS=("IMAGE_TAG" "DOCKERFILE_PATH" "CONTEXT_PATH" "DOCKER_USERNAME" "DOCKER_DEV_REPO" "DOCKERHUB_TOKEN")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: Required variable $var is not set in $BUILD_CONFIG_FILE!"
    exit 1
  else
    echo "$var = ${!var}"
  fi
done

FULL_IMAGE_NAME="$DOCKER_USERNAME/$DOCKER_DEV_REPO:$IMAGE_TAG"

#check if docker is installed
if ! [ -x "$(command -v docker)" ]; then
  echo "Error: Docker is not installed. Please install Docker and try again."
  exit 1
fi

#check if dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
  echo "Error: Dockerfile not found at $DOCKERFILE_PATH"
  exit 1
fi

#check if docker credentials file exists
if [ ! -f "$DOCKERHUB_TOKEN" ]; then
  echo "Error: Credentials file not found at $DOCKERHUB_TOKEN"
  exit 1
fi

#build the docker image
echo "Building Docker image..."
docker build -t "$FULL_IMAGE_NAME" -f "$DOCKERFILE_PATH" "$CONTEXT_PATH"

#check if the build was successful
if [ $? -eq 0 ]; then
  echo "Docker image $FULL_IMAGE_NAME built successfully."
else
  echo "Error: Failed to build Docker image."
  exit 1
fi

#login into docker hub with docker credentials
echo "logining into docker hub..."
cat "$DOCKERHUB_TOKEN" | docker login -u "$DOCKER_USERNAME" --password-stdin

#push image to docker hub
echo "Pushing image to Docker Hub..."
docker push "$FULL_IMAGE_NAME"

#verify the image push
echo "Verifying if the image was pushed to Docker Hub..."
if docker manifest inspect "$FULL_IMAGE_NAME" &>/dev/null; then
  echo "Docker image $FULL_IMAGE_NAME has been successfully pushed to Docker Hub"
else
  echo "Error: Failed to verify the image on Docker Hub. Please check your Docker Hub repository."
  exit 1
fi

echo "List of docker images created"
docker images

echo "Logout of Docker Hub"
docker logout