#!/bin/bash
yum update -y
yum install -y curl jq
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

sudo yum install docker -y
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker root
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock

docker --version

mkdir -p gateway
cd gateway
mkdir -p scripts

cat << EOF > scripts/BeforeInstall.sh
#!/bin/bash
if [ -d /opt/scripts/ ]; then
    sudo rm -rf /opt/scripts/
fi

mkdir -p /opt/scripts/
EOF
chmod +x scripts/BeforeInstall.sh

cat << EOF > scripts/AfterInstall.sh
#!/bin/bash
sudo yum install docker -y
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker root
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock

docker --version
EOF
chmod +x scripts/AfterInstall.sh

cat << EOF > scripts/ApplicationStart.sh
#!/bin/bash
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com
docker pull 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com/gateway:latest
docker tag 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com/gateway:latest gateway:latest
docker run -d -p 8080:8080 gateway:latest
aws ecr batch-delete-image --repository-name gateway --image-ids imageTag=latest
EOF
chmod +x scripts/ApplicationStart.sh

cat << EOF > scripts/ApplicationStop.sh
#!/bin/bash
docker rm -f \$(docker ps -a -q)
docker rmi -f \$(docker images -q)
EOF
chmod +x scripts/ApplicationStop.sh

cat << EOF > buildspec.yml
version: 0.2

env:
  variables:
    AWS_REGION: "REGION"
    ECR_REPO_NAME: "ECR_REPO_NAME"
    AWS_ACCOUNT_ID: "AWS_ACCOUNT_ID"

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region \$AWS_REGION | docker login --username AWS --password-stdin \$AWS_ACCOUNT_ID.dkr.ecr.\$AWS_REGION.amazonaws.com
  build:
    commands:
      - echo Build started on \`date\`
      - echo Building the Docker image...
      - docker build -t \$ECR_REPO_NAME .
      - docker tag \$ECR_REPO_NAME:latest \$AWS_ACCOUNT_ID.dkr.ecr.\$AWS_REGION.amazonaws.com/\$ECR_REPO_NAME:latest
  post_build:
    commands:
      - echo Build completed on \`date\`
      - echo Pushing the Docker image...
      - docker push \$AWS_ACCOUNT_ID.dkr.ecr.\$AWS_REGION.amazonaws.com/\$ECR_REPO_NAME:latest
artifacts:
  files:
    - appspec.yml
    - scripts/AfterInstall.sh
    - scripts/ApplicationStart.sh
    - scripts/ApplicationStop.sh
EOF

cat << EOF > appspec.yml
version: 0.0
os: linux
files:
  - source: /
    destination: /opt/scripts/
hooks:
  AfterInstall:
    - location: scripts/AfterInstall.sh
      timeout: 60
      runas: root
  ApplicationStart:
    - location: scripts/ApplicationStart.sh
      timeout: 60
      runas: root
  ApplicationStop:
    - location: scripts/ApplicationStop.sh
      timeout: 60
      runas: root
EOF

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

# ECR
sudo aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t gateway .
docker tag gateway:latest 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com/gateway:latest
docker push 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com/gateway:latest
docker run -d -p 8080:8080 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com/gateway:latest

# Git
export GITHUB_TOKEN="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"
git config --global credential.helper "!aws codecommit credential-helper $@"
git config --global credential.UseHttpPath true
git init
git remote add origin https://wlstmd:${GITHUB_TOKEN}@github.com/wlstmd/jnc-commit.git
git add .
git commit -m "init"
git branch main
git checkout main
git push origin main
