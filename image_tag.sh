#!/bin/bash

# Check if image tag is provided
if [ -z "$1" ]; then
  echo "Error: Image tag argument is missing."
  exit 1
fi

IMAGE_TAG=$1
CONFIG_FILE="./configurations/config.ini"

# Create or update the config.ini file
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configurations file $CONFIG_FILE not found!"
  exit 1
fi

# Add or update the image tag
if grep -q "IMAGE_TAG" "$CONFIG_FILE"; then
  sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=$IMAGE_TAG/" "$CONFIG_FILE"
else
  echo "IMAGE_TAG=$IMAGE_TAG" >> "$CONFIG_FILE"
fi

echo "Updated $CONFIG_FILE with IMAGE_TAG=$IMAGE_TAG"

######################################################################
#Add this file to Jenins Pipeline Job Stage
#use this cmd when executing "./image_tag.sh $BUILD_NUMBER"
######################################################################