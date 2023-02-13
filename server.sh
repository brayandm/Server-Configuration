#!/bin/bash

#Setting environment variables
source .env

#Updating the packages
apt-get update

#Installing docker compose
apt-get install -y docker-compose

#Giving permissions to the docker sock
chmod 700 /var/run/docker.sock

#Creating the docker network
docker network create $SCRIPT_ENV_DOCKER_NETWORK

#Login to Docker
docker login -u$SCRIPT_ENV_DOCKER_USER -p$SCRIPT_ENV_DOCKER_PASSWORD $SCRIPT_ENV_DOCKER_HOST

#Downloading the gitlab runner
curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_$SCRIPT_ENV_LINUX_ARCHITECTURE.deb"

#Installing the gitlab runner
dpkg -i gitlab-runner_$SCRIPT_ENV_LINUX_ARCHITECTURE.deb

#Registering the gitlab runner
gitlab-runner register \
  --non-interactive \
  --url "$SCRIPT_ENV_RUNNER_REGISTRATION_HOST" \
  --registration-token "$SCRIPT_ENV_RUNNER_REGISTRATION_TOKEN" \
  --executor "shell" \
  --description "$SCRIPT_ENV_RUNNER_REGISTRATION_DESCRIPTION" \
  --tag-list "$SCRIPT_ENV_RUNNER_REGISTRATION_TAGS"
  
#Running the gitlab runner
gitlab-runner run &

#Getting up the nginx proxy manager
docker-compose up -d

#Removing environment variables
rm .env
