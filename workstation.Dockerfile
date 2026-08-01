FROM docker:28-dind

RUN apk add --no-cache \
    bash \
    coreutils \
    curl \
    file \
    git \
    jq \
    shadow

WORKDIR /workspace
