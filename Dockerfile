# Maverick's Dockerfile for Qira
# https://github.com/maverickwoo/qira-docker

# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
FROM phusion/baseimage:0.9.15
MAINTAINER Maverick Woo <maverick.woo.remove.these.four.words@gmail.com>

# setup environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root

# use baseimage-docker's init system
CMD ["/sbin/my_init"]

#### STABLE BEGIN ####

# insert my ssh key, and do it early to aid debug
# (path to ADD and COPY must be absolute since it is not passed to sh)
ADD phraseless_rsa2.pub /root/.ssh/authorized_keys
RUN chmod 600 ~/.ssh/authorized_keys

# IDA demo
COPY idademo_linux.tgz /root/idademo_linux.tgz
RUN echo '[2014-12-17] IDA'; \
    tar -C /root -zxf /root/idademo_linux.tgz; \
    rm /root/idademo_linux.tgz

#### STABLE END ####

# update APT (I want this separate and cached by date)
RUN echo '[2014-12-17] apt-get update'; \
    apt-get update

# cloning qira needs git
RUN echo '[2014-12-17] apt-get install git'; \
    apt-get install -y git

# install my own stuff into the image
RUN echo '[2014-12-17] apt-get install misc'; \
    apt-get install -y \
            htop \
            socat \
            strace \
            tig \
            tmux \
            `#end`

#### QIRA BEGIN ####

# clone qira and run gc to make sure there is minimal change in pull
RUN echo '[2014-12-17] git clone qira'; \
    git clone https://github.com/BinaryAnalysisPlatform/qira.git ~/qira; \
    cd ~/qira; \
    git gc

# cache ARM libraries (this is stable after `apt-get update`)
RUN echo '[2014-12-17] cache ARM libraries'; \
    apt-get install -y \
            debootstrap \
            `#end`
RUN echo '[2014-12-17] fetchlibs'; \
    cd ~/qira; \
    ./fetchlibs.sh

# cache other qira dependencies (these are installed by install.sh)
RUN echo '[2014-12-17] apt-get install qira dependencies'; \
    apt-get install -y \
            build-essential \
            debootstrap \
            graphviz \
            libjpeg-dev \
            python-dev \
            python-pip \
            unzip \
            wget \
            zlib1g-dev \
            `#end`

# cache qemu build (pump date if you want to)
RUN echo '[2014-12-17] build qemu'; \
    cd ~/qira; \
    ./qemu_build.sh

# pull qira one more time since I cache the clone (always pump this date)
RUN echo '[2015-01-18]'; \
    cd ~/qira; \
    git pull

# install qira---if the pull is no-op, then this is a cache hit
RUN echo '[2014-12-17]'; \
    cd ~/qira; \
    ./install.sh

#### QIRA END ####

# install more stuff that I missed above (think of this as a hot-patch)
RUN echo '[2015-01-18] apt-get staging area'; \
    apt-get install -y \
            bash \
            realpath \
            `#end`

# clean up APT and temp files
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# configure qira to my taste
RUN echo "HOST = '0.0.0.0'" >> ~/qira/middleware/qira_config.py

# restore DEBIAN_FRONTEND
ENV DEBIAN_FRONTEND newt
