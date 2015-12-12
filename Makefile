TAG = $(shell date +%m%d)

all: help

build:
	docker build -t qira:$(TAG) .

run:
	docker run --privileged -d -p 12345:3002 qira:1217

enter:
	sh docker-ssh 9098

download:
	curl -k -L -o idademo_linux.tgz https://out7.hex-rays.com/files/idademo68_linux.tgz
	curl -k -L https://github.com/phusion/baseimage-docker/archive/master.tar.gz | tar xzf - && rm .baseimage_docker_insecure_key && mv baseimage-docker-master .baseimage_docker_insecure_key
	cp ~/.ssh/id_rsa.pub phraseless_rsa2.pub

help:
	echo "Usage: make <build|run|enter|download|help>"


.PHONY: build run enter help
.SILENT: build run enter help
