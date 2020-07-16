#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

sudo service docker start
sudo docker build --tag pilertest:latest .

cd compose-clean-test

sudo docker-compose rm -sf

sudo rm /var/piler-test-config -rf && true
sudo rm /var/piler-test-data -rf && true
sudo mkdir /var/piler-test-config
sudo mkdir /var/piler-test-data
sudo rm /var/piler-test-mariadb -rf && true
sudo mkdir /var/piler-test-mariadb

sudo docker-compose up -d
 
echo "Docker Piler instance is up and running: Show the logs"
sudo docker logs composecleantest_service_1 --follow