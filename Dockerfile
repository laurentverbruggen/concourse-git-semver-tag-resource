FROM gliderlabs/alpine:3.4

RUN apk --update add \
  ca-certificates \
  bash \
  jq \
  nodejs \
  git

RUN npm install -g semver

# can't `git pull` unless we set these
RUN git config --global user.email "git@localhost" && \
    git config --global user.name "git"

ADD assets/ /opt/resource/
RUN chmod +x /opt/resource/*
