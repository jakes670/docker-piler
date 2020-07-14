#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

sudo service docker start
sudo rm /var/piler-1-config -rf && true
sudo rm /var/piler-1-data -rf && true
sudo docker build --tag pilertest:latest . 
sudo docker rm --force piler-1 && true
sudo docker run -d --name piler-1 \
 -p 2525:25 -p 8025:80 \
 -v /var/piler-1-data:/var/piler \
 -v /var/piler-1-config:/etc/piler \
 -e PILER_HOST=localhost pilertest:latest
 
echo "Docker Piler instance is up and running: Show the logs\n"
sudo docker logs piler-1 --follow