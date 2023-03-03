#!/bin/bash

#Setting environment variables
source .env

#Updating the packages
apt-get update

#Installing docker compose
apt-get install -y docker-compose

#Giving permissions to the docker sock
chmod 777 /var/run/docker.sock

#Creating the docker network
docker network create $SCRIPT_ENV_DOCKER_NETWORK

#Login to Docker (Warning!!! do it inside gitlab-runner user)
docker login -u $SCRIPT_ENV_DOCKER_USER -p $SCRIPT_ENV_DOCKER_PASSWORD $SCRIPT_ENV_DOCKER_HOST

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

#Create nginx proxy reverse configuration file
tee custom.conf <<EOF
server {
    listen 80;

    server_name $SCRIPT_ENV_DOMAIN_NAME_WEB1;

    location / {
        proxy_pass http://$SCRIPT_ENV_SERVER_IP:$SCRIPT_ENV_PORT_WEB1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 80;

    server_name $SCRIPT_ENV_DOMAIN_NAME_WEB2;

    location / {
        proxy_pass http://$SCRIPT_ENV_SERVER_IP:$SCRIPT_ENV_PORT_WEB2;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

#Getting up the nginx proxy manager
docker-compose up -d

#Removing environment variables
rm .env

#Running the gitlab runner
gitlab-runner run &