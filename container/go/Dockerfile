# syntax=docker/dockerfile:1

# should match the go directive in sdks/go/go.mod
ARG GO_VERSION=1.26

# ---- build stage -------------------------------------------------------------
FROM golang:${GO_VERSION} AS build

ARG EXAMPLE
ARG SDK_PATH=sdks/go

WORKDIR /src

# deps first so this layer caches when only source changes
COPY ${SDK_PATH}/go.mod ${SDK_PATH}/go.sum ./
RUN go mod download

# then the rest of the SDK source (this repo builds itself)
COPY ${SDK_PATH}/ ./

RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" \
    -o /out/entrypoint ./examples/${EXAMPLE} \
    && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" \
    -o /out/healthprobe ./cmd/catena-healthcheck

# ---- runtime stage -----------------------------------------------------------
FROM gcr.io/distroless/static:nonroot AS runtime

ARG EXAMPLE

WORKDIR /app

COPY --from=build /out/entrypoint /app/entrypoint
COPY --from=build /out/healthprobe /app/healthprobe

# no shell on distroless, so a standalone static probe stands in for healthcheck.sh;
# it reads CATENA_USE_REST / CATENA_USE_GRPC and checks whatever is enabled
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD ["/app/healthprobe"]

ENTRYPOINT ["/app/entrypoint"]
