FROM ubuntu:20.04
LABEL authors="Fred Dixon, Anton Georgiev"

ARG CACHE_BUST=1

# In order to update, use:
# docker build -t build-focal .; docker rmi -f $(docker images --filter "dangling=true" -q)

# Tell debconf to run in non-interactive mode
ENV DEBIAN_FRONTEND noninteractive

ENV GRADLE_VERSION=7.3.1
ENV GRAILS_VERSION=5.3.2
ENV SBT_VERSION=1.6.2

ENV GRADLE_HOME /tools/gradle-${GRADLE_VERSION}
ENV GRAILS_HOME /tools/grails/grails-${GRAILS_VERSION}
ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64
ENV SBT_HOME /tools/sbt

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
  python \
  python-apt \
  python-debian \
  python3-yaml \
  subversion \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# ubuntu speciphic:
RUN apt-get update && apt-get install -y \
  software-properties-common \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# For FreeSWITCH
RUN add-apt-repository -y ppa:bigbluebutton/support  \
  && apt-get update \
  && apt-get install -y \
  libopusenc-dev \
  sox \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt install -y \
  autoconf \
  automake \
  libcurl4-openssl-dev \
  libedit-dev \
  libjpeg-dev \
  libldns-dev \
  libncurses5 \
  libncurses5-dev \
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
  libavresample-dev     	\
  libavutil-dev           \
  libdb-dev               \
  libexpat1-dev           \
  libgdbm-dev             \
  libgnutls28-dev         \
  libladspa-ocaml-dev     \
  liblua5.2-dev           \
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
  libtiff5-dev            \
  libv8-dev               \
  libvlc-dev              \
  libvorbis-dev           \
  libx11-dev              \
  odbc-postgresql         \
  openssl                 \
  opus-tools              \
  portaudio19-dev         \
  python-dev              \
  python3-pip             \
  unixodbc-dev            \
  yasm                    \
  jq                      \
  moreutils               \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*


RUN update-java-alternatives -s java-1.17.0-openjdk-amd64

# Added to build the HTML5 client
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get update && apt-get install -y nodejs

RUN curl https://install.meteor.com/?release=2.13 | sh
RUN npm install npm@9.5.1 -g

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

RUN wget --no-verbose https://github.com/grails/grails-core/releases/download/v${GRAILS_VERSION}/grails-${GRAILS_VERSION}.zip \
  && unzip -q grails-${GRAILS_VERSION}.zip \
  && ln -s ${PWD}/grails-${GRAILS_VERSION}/bin/grails /usr/bin/grails \
  && rm -f grails-${GRAILS_VERSION}.zip


RUN wget --no-verbose https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-all.zip \
  && unzip -q gradle-${GRADLE_VERSION}-all.zip \
  && ln -s ${PWD}/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle \
  && rm -f gradle-${GRADLE_VERSION}-all.zip

RUN wget --no-verbose https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.zip \
  && unzip -q sbt-${SBT_VERSION}.zip \
  && ln -s ${PWD}/sbt/bin/sbt /usr/bin/sbt \
  && rm -f sbt-${SBT_VERSION}.zip

RUN cd ..
