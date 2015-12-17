TAG = qira
NAME = qira
SPORT = 9098
LPORT = 12345
LLPORT = 3002
PUBKEY = phraseless_rsa2.pub
PRVKEY = baseimage_docker_insecure_key
IMGURL = https://github.com/phusion/baseimage-docker/archive/master.tar.gz
IDAURL = https://out7.hex-rays.com/files/idademo68_linux.tgz

all: help

build: prepare
	docker build -t $(TAG) .

prepare:
	curl -k -L -o idademo_linux.tgz $(IDAURL)
	curl -k -L $(IMGURL) | tar xzf - && rm .$(PRVKEY) && mv $(PRVKEY) .$(PRVKEY)
	cp ~/.ssh/id_rsa.pub $(PUBKEY)

run: build
	docker run --privileged -d -p $(LPORT):$(LLPORT) --name $(NAME) $(TAG)

enter:
	sh docker-ssh $(SPORT)

help:
	echo "Usage: make <build|run|enter|download|help>" && \
	echo "\$$ make build run enter"

.PHONY: all build run enter help
.SILENT: all build run enter help
