FROM ubuntu:24.04
LABEL authors="Fred Dixon, Anton Georgiev"

ARG CACHE_BUST=1

# In order to update, use:
# docker build -t build-focal .; docker rmi -f $(docker images --filter "dangling=true" -q)

# Tell debconf to run in non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

ENV GO_VERSION=1.27.3
ENV NODE_VERSION=24.22.1
ENV SBT_VERSION=1.10.7

ENV GOPATH=/tools/go
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV SBT_HOME=/tools/sbt

# Make sure the repository information is up to date
RUN apt-get update && apt-get install -y \
  ca-certificates \
  wget            \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# base (unzip: sbt zip here, bbb-freeswitch-sounds and bbb-presentation-video in the package builds;
# lsb-release: coturn's configure consults lsb_release and picks its Ubuntu code path from it)
RUN apt-get update && apt-get install -y \
  build-essential \
  curl \
  git-core \
  lsb-release \
  ruby-dev \
  unzip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Build packages (equivs: the bigbluebutton meta-package build runs equivs-build; it depends on debhelper)
RUN apt-get update && apt-get -y install --no-install-recommends \
  equivs \
  fakeroot \
  git \
  openjdk-21-jdk \
  libyaml-dev \
  python3 \
  python3-yaml \
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
  libpcre2-dev \
  libspeexdsp-dev \
  libsqlite3-dev \
  libtool \
  libtool-bin \
  make \
  pkg-config  \
  sqlite3 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y  \
  bison	              		\
  cmake                   \
  gawk                    \
  libexpat1-dev           \
  liblua5.4-dev           \
  libopusfile-dev         \
  libsndfile-dev          \
  libspeex-dev            \
  libssl-dev              \
  libsctp-dev             \
  libtiff-dev             \
  uuid-dev                \
  openssl                 \
  opus-tools              \
  python3-dev              \
  python3-pip             \
  yasm                    \
  jq                      \
  moreutils               \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*


RUN update-java-alternatives -s java-1.21.0-openjdk-amd64

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
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


# sbt and Go are extracted into /, where they have always landed (the former "RUN cd tools" never
# took effect): Go records GOROOT and GOPATH in every binary it builds, so moving them changes
# the packages. The /usr/bin links point at them.
RUN wget --no-verbose https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.zip \
  && unzip -q sbt-${SBT_VERSION}.zip \
  && ln -s ${PWD}/sbt/bin/sbt /usr/bin/sbt \
  && rm -f sbt-${SBT_VERSION}.zip

RUN wget --no-verbose https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
  && tar -xzf go${GO_VERSION}.linux-amd64.tar.gz \
  && ln -s ${PWD}/go/bin/go /usr/bin/go \
  && rm go${GO_VERSION}.linux-amd64.tar.gz
