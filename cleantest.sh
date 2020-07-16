#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

sudo service docker start
sudo rm /var/piler-1-config -rf && true
sudo rm /var/piler-1-data -rf && true
sudo rm /var/piler-1-mariadb -rf && true
sudo docker build --tag pilertest:latest . 

cp docker-compose.example.yml docker-compose.yml

docker-compose up -d
 
echo "Docker Piler instance is up and running: Show the logs\n"
sudo docker logs piler-1 --follow