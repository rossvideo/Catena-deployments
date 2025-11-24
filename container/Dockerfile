FROM ubuntu:24.04 AS base

ARG CONNECTION
ARG EXAMPLE
ARG EXAMPLE_PATH
ARG WORKDIR
ARG USER_GROUP=1000:1000

ENV CATENA_CONNECTION=${CONNECTION}
ENV CATENA_EXAMPLE=${EXAMPLE}

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

USER ${USER_GROUP}

WORKDIR ${WORKDIR}

COPY --chmod=755 --chown=${USER_GROUP} ${EXAMPLE_PATH} ${WORKDIR}/${CONNECTION}/${EXAMPLE}
COPY --chmod=755 container/entrypoint.sh /entrypoint.sh
COPY --chmod=755 container/healthcheck.sh /healthcheck.sh

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD /healthcheck.sh

RUN mkdir -p ${WORKDIR}/logs && mkdir -p ${WORKDIR}/static

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]

FROM base AS REST

ENV CATENA_PORT=443

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    libboost-url1.83.0 \
    && rm -rf /var/lib/apt/lists/*

USER ${USER_GROUP}

FROM base AS gRPC

ENV CATENA_PORT=6254

COPY --from=ghcr.io/grpc-ecosystem/grpc-health-probe:v0.4.38 /ko-app/grpc-health-probe /bin/grpc_health_probe
