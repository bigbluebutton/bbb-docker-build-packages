FROM ubuntu:24.04
LABEL authors="Fred Dixon, Anton Georgiev"

ARG CACHE_BUST=1

# In order to update, use:
# docker build -t build-focal .; docker rmi -f $(docker images --filter "dangling=true" -q)

# Tell debconf to run in non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

ENV GO_VERSION=1.26.5
ENV GRADLE_VERSION=8.14.3
ENV GRAILS_VERSION=7.0.8
ENV NODE_VERSION=22.23.1
ENV SBT_VERSION=1.6.2

ENV GRADLE_HOME=/tools/gradle-${GRADLE_VERSION}
ENV GRAILS_HOME=/tools/grails/grails-${GRAILS_VERSION}
ENV GOPATH=/tools/go
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV SBT_HOME=/tools/sbt

RUN touch /tmp/a.txt

# Make sure the repository information is up to date
RUN apt-get update && apt-get install -y \
  apt-utils       \
  ca-certificates \
  openssh-server  \
  vim             \
  wget            \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# base
RUN apt-get update && apt-get install -y \
  apt-transport-https \
  build-essential \
  checkinstall \
  curl \
  git-core \
  lsb-release \
  ruby-dev

# Build packages
RUN apt-get update && apt-get -y install --no-install-recommends \
  cdbs \
  debhelper \
  devscripts \
  equivs \
  fakeroot \
  git \
  openjdk-17-jdk \
  libfreemarker-java \
  libgoogle-gson-java \
  libmaven-assembly-plugin-java \
  libmaven-compiler-plugin-java \
  libyaml-dev \
  maven-debian-helper \
  python3 \
  python3-apt \
  python3-debian \
  python3-yaml \
  subversion \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# ubuntu speciphic:
RUN apt-get update && apt-get install -y \
  software-properties-common \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# For FreeSWITCH (libopusenc-dev is in noble's main repo, no PPA needed)
RUN apt-get update && apt-get install -y \
  libopusenc-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
  autoconf \
  automake \
  libcurl4-openssl-dev \
  libedit-dev \
  libjpeg-dev \
  libldns-dev \
  libncurses6 \
  libncurses-dev \
  libpcre3-dev \
  libspeexdsp-dev \
  libsqlite3-dev \
  libtool \
  libtool-bin \
  make \
  pkg-config  \
  sqlite3 \
  unixodbc \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y  \
  bison	              		\
  cmake                   \
  gawk                    \
  groff                   \
  groff-base	          	\
  liba52-0.7.4-dev        \
  libapr1-dev             \
  libasound2-dev          \
  libavcodec-dev          \
  libavformat-dev         \
 # libavresample-dev     	\
  libavutil-dev           \
  libdb-dev               \
  libexpat1-dev           \
  libgdbm-dev             \
  libgnutls28-dev         \
  libladspa-ocaml-dev     \
  liblua5.4-dev           \
  libmemcached-dev        \
  libmp3lame-dev          \
  libogg-dev              \
  libopusfile-dev         \
  libperl-dev		          \
  libpq-dev               \
  libsndfile-dev          \
  libsnmp-dev             \
  libspeex-dev            \
  libssl-dev              \
  libswscale-dev          \
  libtiff-dev             \
  libvlc-dev              \
  libvorbis-dev           \
  libx11-dev              \
  odbc-postgresql         \
  openssl                 \
  opus-tools              \
  portaudio19-dev         \
  python3-dev              \
  python3-pip             \
  unixodbc-dev            \
  yasm                    \
  jq                      \
  moreutils               \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*


RUN update-java-alternatives -s java-1.17.0-openjdk-amd64

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

# had to drop params
RUN gem install fpm -f

# needed for bbb-record-core
RUN apt-get update && apt-get install -y  \
  libsystemd-dev \
  ruby-bundler \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*


RUN mkdir tools
RUN cd tools

ENV APACHE_GRAILS=apache-grails-${GRAILS_VERSION}-bin
RUN wget --no-verbose https://github.com/apache/grails-core/releases/download/v${GRAILS_VERSION}/${APACHE_GRAILS}.zip \
  && unzip -q ${APACHE_GRAILS}.zip \
  && ln -s ${PWD}/${APACHE_GRAILS}/bin/grails /usr/bin/grails \
  && rm -f ${APACHE_GRAILS}.zip

RUN wget --no-verbose https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-all.zip \
  && unzip -q gradle-${GRADLE_VERSION}-all.zip \
  && ln -s ${PWD}/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle \
  && rm -f gradle-${GRADLE_VERSION}-all.zip

RUN wget --no-verbose https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.zip \
  && unzip -q sbt-${SBT_VERSION}.zip \
  && ln -s ${PWD}/sbt/bin/sbt /usr/bin/sbt \
  && rm -f sbt-${SBT_VERSION}.zip

RUN wget --no-verbose https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
  && tar -xzf go${GO_VERSION}.linux-amd64.tar.gz \
  && ln -s ${PWD}/go/bin/go /usr/bin/go \
  && rm go${GO_VERSION}.linux-amd64.tar.gz

RUN cd ..
