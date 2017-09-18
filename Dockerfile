FROM debian:stretch
MAINTAINER Adrien Waksberg "mpw@yae.im"

RUN apt update
RUN apt dist-upgrade -y

RUN apt install -y procps gnupg1 curl git
RUN ln -snvf /usr/bin/gpg1 /usr/bin/gpg
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN echo 'source "/usr/local/rvm/scripts/rvm"' >> /etc/bash.bashrc

run apt install -y patch bzip2 gawk g++ gcc make libc6-dev patch zlib1g-dev libyaml-dev libsqlite3-dev \
                   sqlite3 autoconf libgmp-dev libgdbm-dev libncurses5-dev automake libtool bison \
                   pkg-config libffi-dev libgmp-dev libreadline-dev libssl-dev

RUN /bin/bash -l -c "rvm install 2.4.2"
RUN /bin/bash -l -c "rvm install 2.3.5"
RUN /bin/bash -l -c "rvm install 2.2.8"
RUN /bin/bash -l -c "rvm install 2.1.10"
