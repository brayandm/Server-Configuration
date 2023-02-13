#!/bin/bash

#Setting environment variables
source .env

#Copying the environment variables to the server
scp .env $SCRIPT_ENV_SERVER_USER@$SCRIPT_ENV_SERVER_IP:/root/

#Copying the script to the server
scp server.sh $SCRIPT_ENV_SERVER_USER@$SCRIPT_ENV_SERVER_IP:/root/

#Copying the nginx proxy manager docker compose to the server
scp docker-compose.yml $SCRIPT_ENV_SERVER_USER@$SCRIPT_ENV_SERVER_IP:/root/

#Running the script on the server
ssh $SCRIPT_ENV_SERVER_USER@$SCRIPT_ENV_SERVER_IP "bash server.sh"
