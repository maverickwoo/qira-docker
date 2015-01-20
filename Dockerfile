# Maverick's Dockerfile for Qira
# https://github.com/maverickwoo/qira-docker

# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
FROM phusion/baseimage:0.9.15
MAINTAINER Maverick Woo <maverick.woo.remove.these.four.words@gmail.com>

# setup environment variables
ENV HOME /root

# use baseimage-docker's init system
CMD ["/sbin/my_init"]

#### STABLE STUFF ####

# insert phraseless ssh key, and do it early to aid debug
# (path to ADD and COPY must be absolute since it is not passed to sh)
ADD phraseless_rsa2.pub /root/.ssh/authorized_keys
RUN chmod 600 ~/.ssh/authorized_keys

# insert IDA demo
COPY idademo_linux.tgz /root/idademo_linux.tgz
RUN echo '[2014-12-17] IDA'; \
    tar -C /root -zxf /root/idademo_linux.tgz; \
    rm /root/idademo_linux.tgz

# add APT
RUN echo '[2015-01-19] add-apt-repository'; \
    add-apt-repository -s -y ppa:avsm/ocaml42+opam12

# update APT
RUN echo '[2014-12-17] apt-get update'; \
    DEBIAN_FRONTEND=noninteractive apt-get update

# install my own stuff into the image
RUN echo '[2015-01-19] apt-get install misc'; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
                   archivemount \
                   bash \
                   git \
                   htop \
                   qemu-user-static \
                   realpath \
                   socat \
                   strace \
                   tig \
                   tmux \
                   `#end`

#### CACHE ####

# BAP dependencies
RUN echo '[2015-01-19] cache BAP dependencies'; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
                   clang \
                   libgmp-dev                `#zarith` \
                   libncurses5-dev           `#ocamlfind` \
                   libzmq3-dev \
                   llvm \
                   m4                        `#ocamlfind` \
                   make \
                   ocaml \
                   opam \
                   time                      `#bitstring` \
                   `#end`

# install new OCaml stack
RUN echo '[2015-01-19] opam init'; \
    opam init -a; \
    sed -ri 's/^(jobs:).*/\1 '$(grep -cF processor /proc/cpuinfo)'/' ~/.opam/config; \
    opam switch install -v 0119 -A 4.02.1+PIC; \
    eval `opam config env`

# clone Qira and run gc to make sure there is minimal change in pull
RUN echo '[2015-01-19] git clone qira'; \
    git clone -b integration-with-bap https://github.com/ivg/qira ~/qira; \
    cd ~/qira; \
    git gc

# ARM libraries (this is stable after `apt-get update`)
RUN echo '[2014-12-17] cache ARM libraries'; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y debootstrap
RUN echo '[2014-12-17] fetchlibs'; \
    cd ~/qira; \
    DEBIAN_FRONTEND=noninteractive ./fetchlibs.sh

# other Qira dependencies (installed by install.sh)
RUN echo '[2014-12-17] apt-get install qira dependencies'; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
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

# build qemu once (pump date if you want to rebuild)
RUN echo '[2014-12-17] build qemu'; \
    cd ~/qira; \
    ./qemu_build.sh

#### COMPILE ####

# install bap
RUN echo '[2015-01-19] opam install bap'; \
    opam install -y bap

# pull qira one last time since I cache the clone (always pump this date)
RUN echo '[2015-01-19]'; \
    cd ~/qira; \
    git pull

# patch capstone_build.sh to use github for availability
RUN echo '[2015-01-19] patch capstone_build'; \
    sed -ri 's|wget (.*)|wget -O capstone-3.0.tgz https://github.com/aquynh/capstone/archive/3.0.tar.gz|' ~/qira/capstone_build.sh

# install qira---if the pull is no-op, then this is a cache hit
RUN echo '[2014-12-17]'; \
    cd ~/qira; \
    ./install.sh

#### MISC ####

# configure qira to my taste
RUN echo "HOST = '0.0.0.0'" >> ~/qira/middleware/qira_config.py

# install stuff that I have missed above (think of this as a hot-patch)
RUN echo '[2015-01-19] apt-get staging area'; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
                   bash \
                   `#end`

# clean up temp files
RUN rm -rf /tmp/* /var/tmp/*

# clean up APT and temp files (commented out---not that useful in practice)
# RUN apt-get clean && rm -rf /var/lib/apt/lists/*
