#!/usr/bin/env bash
sudo apt-get install libffi-dev libssl-dev -y;
sudo apt-get install git -y;
sudo apt-get install python3-pip -y;

curl -sSL https://get.docker.com | sh;
sudo usermod -aG docker pi;

sudo pip3 install docker-compose;

docker network create homereponet;
docker-compose up -d;