#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

sudo service docker start
sudo docker build --tag pilertest:latest . 
sudo docker rm --force piler-1 && true
sudo docker rm --force piler-2 && true
sudo docker run -d --name piler-2 \
  -p 2525:25 -p 8025:80 \
  -v /var/piler-2-data:/var/piler \
  -v /var/piler-2-config:/etc/piler \
  -v /var/piler-2-mariadb:/var/lib/mysql:Z \
 -e PILER_HOST=localhost pilertest:latest
 
echo "Docker Piler instance is up and running: Show the logs\n"
sudo docker logs piler-2 --follow