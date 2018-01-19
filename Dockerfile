## Use alpine as build time and runtime image
FROM alpine:3.7@sha256:7df6db5aa61ae9480f52f0b3a06a140ab98d427f86d8d5de0bedab9b8df6b1c0 as build-alpine

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

## Copy requirements.txt first and install Python depenendcies,
## to optimise build times by using cache when dependencies
## didn't change
RUN mkdir /src
WORKDIR /src
COPY requirements.txt /src
RUN pip install --requirement requirements.txt
## Copy the rest of the model source tree and train the model
COPY . /src
RUN python train_iris.py

## Copy source code and Python dependencies to the saging root tree
RUN mkdir -p /out/src && cp -r /src/* /out/src/
RUN mkdir -p /out/usr/lib/python2.7/ && cp -r /usr/lib/python2.7/* /out/usr/lib/python2.7/

## Use Seldon Core wrapper image to wrap the model source code
FROM seldonio/core-python-wrapper:0.4 as build-wrapper

ARG MODEL_NAME
ARG IMAGE_VERSION
ARG IMAGE_REPO

## Copy staging diretory here
COPY --from=build-alpine /out /out
## Wrap the Python model
WORKDIR /wrappers/python
RUN python wrap_model.py /out/src $MODEL_NAME $IMAGE_VERSION $IMAGE_REPO --force

## Copy wrapped model source code into staging tree and cleanup what is not neccessary at runtime
RUN mkdir -p /out/microservice && cp -r /out/src/build/* /out/microservice/ && rm -rf /out/src
WORKDIR /out/microservice
RUN rm -f Dockerfile Makefile requirements*.txt build_image.sh push_image.sh
## TODO dockerfile doesn't support build argument interpolation in array notation for ENTRYPOINT & CMD
## to get rid of `/bin/sh` wrapper, it'd help to make $MODEL_NAME an environment variable and let the
## Python script pick it up
RUN printf '#!/bin/sh\nexec python microservice.py %s REST --service-type MODEL --persistence 0' $MODEL_NAME > microservice.sh && chmod +x microservice.sh

## Copy staging root tree onto an empty image
FROM scratch
COPY --from=build-wrapper /out /
WORKDIR /microservice
EXPOSE 5000
ENTRYPOINT ["/microservice/microservice.sh"]
