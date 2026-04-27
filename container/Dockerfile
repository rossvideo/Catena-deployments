FROM ubuntu:24.04 AS base

ARG CONNECTION
ARG EXAMPLE
ARG EXAMPLE_PATH
ARG WORKDIR
ARG USER_GROUP=1000:1000
# The EXAMPLE_CONTAINER_PATH is the path inside the container where the example will be copied to. It is constructed using the WORKDIR, CONNECTION, and EXAMPLE variables.
# not intended to be set by the build, but is used to avoid hardcoding the path in the Dockerfile and to make it easier to change the path if needed.
ARG EXAMPLE_CONTAINER_PATH=${WORKDIR}/${CONNECTION}/${EXAMPLE}

# same as the default in the code, but needs to be set here so that the healthcheck can use it
ENV CATENA_PORT=6254
ENV CATENA_STATIC_ROOT=${EXAMPLE_CONTAINER_PATH}/static

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libcurl4 \
    libavahi-common3 \
    libavahi-client3 \
    libboost-log1.83.0 \
    libboost-program-options1.83.0 \
    && rm -rf /var/lib/apt/lists/*

USER ${USER_GROUP}

WORKDIR ${WORKDIR}

COPY --chmod=755 --chown=${USER_GROUP} ${EXAMPLE_PATH} ${EXAMPLE_CONTAINER_PATH}
COPY --chmod=755 container/healthcheck.sh /healthcheck.sh

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD /healthcheck.sh

RUN mkdir -p ${WORKDIR}/logs \
    && mkdir -p ${CATENA_STATIC_ROOT} \
    && ln -s ${EXAMPLE_CONTAINER_PATH}/${EXAMPLE} ${WORKDIR}/entrypoint

ENTRYPOINT ["./entrypoint"]

FROM base AS REST

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    libboost-url1.83.0 \
    && rm -rf /var/lib/apt/lists/*

USER ${USER_GROUP}

FROM base AS gRPC

COPY --from=ghcr.io/grpc-ecosystem/grpc-health-probe:v0.4.38 /ko-app/grpc-health-probe /bin/grpc_health_probe
