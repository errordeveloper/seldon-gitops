## We use separate dockerfile for this because having this in toplevel
## directory will invalidate the cache each time any files in the repo
## happen to change

## Use alpine 3.7, with a digest, so that rebuilds will be triggered
## by updating the digest
FROM alpine:3.7@sha256:7df6db5aa61ae9480f52f0b3a06a140ab98d427f86d8d5de0bedab9b8df6b1c0

## Install build dependencies
RUN apk add --update \
    build-base \
    freetype-dev \
    gcc \
    gfortran \
    libc6-compat \
    libffi-dev \
    libpng-dev \
    openblas-dev \
    openssl-dev \
    py2-pip \
    python2 \
    python2-dev\
    wget \
    && true

## Symlink missing header, so we can compile numpy
RUN ln -s /usr/include/locale.h /usr/include/xlocale.h

## Copy package manager config to staging root tree
RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
## Install runtime dependencies under staging root tree
RUN apk add --no-cache --initdb --root /out \
    alpine-baselayout \
    busybox \
    ca-certificates \
    freetype \
    libc6-compat \
    libffi \
    libpng \
    libstdc++ \
    musl \
    openblas \
    openssl \
    python2 \
    && true
## Remove package manager residuals
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

## Install Python depenendcies
COPY . /src
RUN pip install --requirement /src/requirements.txt
