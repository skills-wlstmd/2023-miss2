#!/bin/bash
yum update -y
yum install -y curl jq git ruby wget --allowerasing
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

wget https://aws-codedeploy-us-west-2.s3.us-west-2.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

sudo yum install docker -y
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker root
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock

docker --version

cat << EOF > Dockerfile
FROM amazonlinux:latest

WORKDIR /gateway
COPY ./gateway.go .
RUN chmod 777 gateway.go
RUN yum update -y && \
    yum install -y --skip-broken curl golang && \
    go build ./gateway.go
RUN useradd jncuser
USER jncuser
EXPOSE 8080

CMD [ "./gateway" ]
EOF

cat << EOF > gateway.go
package main

import (
	"fmt"
	"net/http"
)

func gateway(w http.ResponseWriter, req *http.Request) {
    fmt.Fprint(w, "UP")
}

func health(w http.ResponseWriter, req *http.Request) {
    fmt.Fprint(w, "OK")
}

func main() {
    http.HandleFunc("/health", health)
    http.HandleFunc("/gateway", gateway)
    http.ListenAndServe(":8080", nil)
}
EOF

sudo aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t gateway .
docker run -d -p 8080:8080 gateway:latest

