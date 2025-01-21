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