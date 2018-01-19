## For the definition of build container, see ./build/Dockerfile
## (that's where requirements.txt files lives also)
ARG BUILD_IMAGE
FROM $BUILD_IMAGE as build-alpine

COPY . /src
WORKDIR /src
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
