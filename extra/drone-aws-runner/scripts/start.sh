#!/bin/bash
sudo yum install docker -y;
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose;
sudo chmod +x /usr/local/bin/docker-compose;
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose;
sudo service docker start;
docker-compose up;