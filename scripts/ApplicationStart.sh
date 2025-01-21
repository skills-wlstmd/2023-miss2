#!/bin/bash
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com
docker pull 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com/gateway:latest
docker tag 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com/gateway:latest gateway:latest
docker run -d -p 8080:8080 gateway:latest
aws ecr batch-delete-image --repository-name gateway --image-ids imageTag=latest
