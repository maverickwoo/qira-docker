# Introduction

The purpose of this repository is to share my `Dockerfile` for running
[Qira](https://github.com/BinaryAnalysisPlatform/qira) in a Docker container. It
is specific to my workflow, but I feel that it is general enough and hopefully
well-written enough for anyone wishing to Docker-ize Qira to base their own
`Dockerfile` on this.

The following files in the repository require some explanations:

* `.baseimage_docker_insecure_key` and `docker-ssh` are copied from
https://github.com/phusion/baseimage-docker/archive/master.tar.gz. The
`install-tools.sh` in the above archive assumes you run it with `sudo` and I am
just __*not so hot*__ on such practice. You want to put the key in your home
directory and the script somewhere on your path.

* `idademo_linux.tgz` is supposed to be an evaluation copy of IDA. The file in
this repo is empty on purpose. You can download the real thing at
https://www.hex-rays.com/products/ida/support/download_demo.shtml. (At work we
have properly licensed IDA, but in this repo I am pointing you to the demo.)

* `phraseless_rsa2.pub` is supposed to be a phraseless ssh public key. It is
intended to be inserted into the Docker container for `docker-ssh` and alike.
The file in this repo is again empty on purpose.

__Note:__ I use the `git update-index --assume-unchanged foo` trick on these two
empty files. You probably want to do that too.)

# Recommended Usage

## Setting up the Container

To setup your container, you can execute:

```bash
$ docker build -t qira:1217 .
```

In the above command line, `qira` is the name of the image ("repository") and
`1217` is a date ("tag").

## Starting the Container

To start the Docker container containing Qira while mapping the host port
`12345` to the container port `3002` (the default http port in Qira), run:

```bash
$ docker run --privileged -d -p 12345:3002 qira:1217
```

The container ID will be printed on the terminal. In this example, let's say the
ID is `9098ec1d03bf699331f9db736a9eb80da7afd33a8ed50a5f3c40d79fe034d18a`.

## Entering the Container

Assuming the above container ID, we can ssh into the container by:

```bash
$ docker-ssh 9098
```

where `9098` is a prefix of the ID that is long enough to disambiguate the ID
among all container IDs in your system.

## Running Qira in the Container

The `Dockerfile` installs Qira in `~/qira` inside the container. Since recent
versions of Qira installs a link at `/usr/local/bin`, the command `qira` should
be on the path automatically.

I recommend running Qira inside a `tmux` session since you often want to analyze
an application with several inputs. For example, this is how you can run Qira on
`/bin/ls` on two different paths:

In one tmux window:
```bash
root@b160c5865bf8:# qira /bin/ls /bin
```

In another tmux window:
```bash
root@b160c5865bf8:# qira /bin/ls /tmp
```

## Interacting with Qira

Once an instance of Qira is running inside the container, launch a browser
session in the _host_:

```bash
$ exo-open http://localhost:12345/
```

where `12345` is your chosen host port when you start the container.

## Stopping the Container

After you are done with a Docker container, you can kill it by `docker rm`. With
our example, this would be:

```bash
$ docker rm -f 9098
```

You can also kill all running containers by:

```bash
$ docker rm -f $(docker ps -a -q)
```

## Updating the Docker Image

Our `Dockerfile` has been written such that the more stable steps are executed
earlier to take advantage of the AUFS cache of Docker. To generate an updated
image based on the latest Qira, you pump the date in the `echo` command
associated with `git pull`. This will force Docker to perform the pull, and if
the pull brings new code, then Docker will re-execute the steps that follow the
pull.

For example, suppose we have built an image on `1217` and we want to get an
updated image on `0118`, we perform:

```bash
$ #manually edit Dockerfile to pump pull date to 2015-01-19
$ docker build -t qira:0119 .
```

After we have obtained the new image, we can erase the old one to reclaim space:

```bash
$ docker rmi qira:1217
```

__Note:__ To utilize the AUFS cache, you want to remove the old image __*only
after*__ you have built the new one.
