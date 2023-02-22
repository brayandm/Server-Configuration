#!/bin/bash

echo "Setting environment variables"
source .env

echo "Updating the packages"
apt-get update

echo "Installing docker compose"
apt-get install -y docker-compose

echo "Giving permissions to the docker sock"
chmod 777 /var/run/docker.sock

echo "Creating the docker network"
docker network create $SCRIPT_ENV_DOCKER_NETWORK

echo "Downloading the gitlab runner"
curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_$SCRIPT_ENV_LINUX_ARCHITECTURE.deb"

echo "Installing the gitlab runner"
dpkg -i gitlab-runner_$SCRIPT_ENV_LINUX_ARCHITECTURE.deb

echo "Registering the gitlab runner"
gitlab-runner register \
  --non-interactive \
  --url "$SCRIPT_ENV_RUNNER_REGISTRATION_HOST" \
  --registration-token "$SCRIPT_ENV_RUNNER_REGISTRATION_TOKEN" \
  --executor "shell" \
  --description "$SCRIPT_ENV_RUNNER_REGISTRATION_DESCRIPTION" \
  --tag-list "$SCRIPT_ENV_RUNNER_REGISTRATION_TAGS"

echo "Installing NginX"
sudo apt install nginx
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'
systemctl status nginx

mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.old

tee /etc/nginx/sites-available/default <<EOF
server {
    listen 443 ssl;
    server_name dev-platform.leaguesofcode.com;

    ssl_certificate  /etc/nginx/certs/loc_cert.pem;
    ssl_certificate_key  /etc/nginx/certs/loc_key.pem;

    client_max_body_size 128M;

    location / {
        proxy_pass       http://127.0.0.1:8003/;
    }
}
server {
    listen 443 ssl;
    server_name dev-api.leaguesofcode.com;

    ssl_certificate  /etc/nginx/certs/loc_cert.pem;
    ssl_certificate_key  /etc/nginx/certs/loc_key.pem;

    client_max_body_size 128M;

    location / {
        proxy_pass       http://127.0.0.1:8004/;
    }
}
EOF

systemctl restart nginx