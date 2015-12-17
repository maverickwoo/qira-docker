TAG = $(shell date +%m%d)
KEY = baseimage_docker_insecure_key
IMGURL = https://github.com/phusion/baseimage-docker/archive/master.tar.gz
IDAURL = https://out7.hex-rays.com/files/idademo68_linux.tgz

all: help

build:
	docker build -t archlinux-qira .

run:
	docker run --privileged -d -p 12345:3002 --name qira archlinux-qira

enter:
	sh docker-ssh 9098

download:
	curl -k -L -o idademo_linux.tgz $(IDAURL)
	curl -k -L $(IMGURL) | tar xzf - && rm .$(KEY) && mv $(KEY) .$(KEY)
	cp ~/.ssh/id_rsa.pub phraseless_rsa2.pub

help:
	echo "Usage: make <build|run|enter|download|help>"

.PHONY: all build run enter help
.SILENT: all build run enter help
