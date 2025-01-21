#!/bin/bash
sudo yum install docker -y
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker root
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock

docker --version