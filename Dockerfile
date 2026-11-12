# Slim BigBlueButton package-build image, ubuntu:24.04 based.
# Same toolchain the build/packages-template/*/build.sh scripts use, minus
# everything nothing calls (Grails, standalone Gradle, nvm, editors, sshd,
# Debian packaging helpers, FreeSWITCH dev libs for modules not in modules.conf).
FROM ubuntu:24.04
LABEL authors="Fred Dixon, Anton Georgiev"

ENV DEBIAN_FRONTEND=noninteractive

ENV GO_VERSION=1.27.4
ENV NODE_VERSION=24.22.3
ENV SBT_VERSION=1.10.7

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
# GOROOT=/go and GOPATH=/tools/go as in the previous image: Go records both paths in every binary it
# builds (the package builds do not pass -trimpath), so keeping them keeps the packages identical.
ENV GOPATH=/tools/go
ENV PATH=/go/bin:/tools/sbt/bin:${PATH}

# No manuals, docs, info pages or locales in a build image; copyright files stay. The empty man directories stay
# because update-alternatives (the JDK postinst, anything apt-get installs during a package build) fails without them.
RUN printf 'path-exclude=/usr/share/doc/*\npath-include=/usr/share/doc/*/copyright\npath-exclude=/usr/share/man/*\npath-exclude=/usr/share/info/*\npath-exclude=/usr/share/locale/*\npath-exclude=/usr/share/lintian/*\n' \
      > /etc/dpkg/dpkg.cfg.d/01-nodoc \
  && rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/locale/* \
  && mkdir -p /usr/share/man/man1 /usr/share/man/man3 /usr/share/man/man5 /usr/share/man/man7 /usr/share/man/man8

# All apt packages in one layer: build toolchain, JDK, Ruby (fpm), and the
# -dev libraries for the FreeSWITCH modules listed in
# build/packages-template/bbb-freeswitch-core/modules.conf plus sofia-sip,
# spandsp, libks and libwebsockets. python3-pip: the bbb-webrtc-sfu build
# compiles the mediasoup worker with meson/ninja fetched by pip. equivs: the
# bigbluebutton meta-package build runs equivs-build. systemd-dev: systemd.pc,
# which bbb-record-core's build.sh queries for the unit directory. libsctp-dev:
# coturn's configure compiles SCTP support when the header is present. lsb-release: coturn's
# configure consults lsb_release and picks its Ubuntu code path from it.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    bzip2 \
    ca-certificates \
    cmake \
    curl \
    equivs \
    fakeroot \
    gawk \
    git \
    jq \
    libtool \
    libtool-bin \
    lsb-release \
    make \
    moreutils \
    openjdk-21-jdk-headless \
    openssl \
    patch \
    pkg-config \
    python3 \
    python3-pip \
    python3-yaml \
    ruby \
    ruby-bundler \
    ruby-dev \
    unzip \
    wget \
    xz-utils \
    yasm \
    libsystemd-dev \
    libcurl4-openssl-dev \
    libedit-dev \
    libexpat1-dev \
    libjpeg-dev \
    libldns-dev \
    liblua5.4-dev \
    libncurses-dev \
    libopus-dev \
    libopusenc-dev \
    libopusfile-dev \
    libpcre2-dev \
    libsndfile1-dev \
    libspeex-dev \
    libspeexdsp-dev \
    libsctp-dev \
    libsqlite3-dev \
    libssl-dev \
    libtiff-dev \
    systemd-dev \
    uuid-dev \
    zlib1g-dev \
  && gem install fpm --no-document \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb /root/.cache /root/.local/share/gem \
       /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/locale/* \
  && mkdir -p /usr/share/man/man1 /usr/share/man/man3 /usr/share/man/man5 /usr/share/man/man7 /usr/share/man/man8

# Node.js from the official tarball into /usr/local (node, npm, npx on PATH).
# The headers are dropped: node-gyp fetches them on demand, and no package in the build compiles an addon against them.
RUN curl -fsSL -o /tmp/node.tar.xz https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz \
  && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner \
       --exclude=CHANGELOG.md --exclude=README.md --exclude=LICENSE \
  && rm -rf /tmp/node.tar.xz /usr/local/include/node /usr/local/share/doc /usr/local/share/man \
  && node --version && npm --version

# Go toolchain in /go (see GOROOT above) without its tests, docs and API files
RUN curl -fsSL -o /tmp/go.tar.gz https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
  && tar -xzf /tmp/go.tar.gz -C / \
  && rm -rf /tmp/go.tar.gz /go/test /go/doc /go/misc /go/api \
  && ln -s /go/bin/go /usr/bin/go \
  && go version

# sbt launcher only. The zip's preloaded repository (150 MB) is dropped: the launcher fetches the sbt
# version each project pins from Maven Central into the ivy cache, which the builds mount and keep.
RUN mkdir -p /tools \
  && curl -fsSL -o /tmp/sbt.zip https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.zip \
  && unzip -q /tmp/sbt.zip -d /tools \
  && rm -rf /tmp/sbt.zip /tools/sbt/lib/local-preloaded \
  && test -x /tools/sbt/bin/sbt
