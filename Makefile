TAG = $(shell date +%m%d)

all: help

build:
	docker build -t qira:$(TAG) .

run:
	docker run --privileged -d -p 12345:3002 qira:1217

enter:
	sh docker-ssh 9098

help:
	echo "Usage: make <build|run|enter|help>"


.PHONY: build run enter help
.SILENT: build run enter help
