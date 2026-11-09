# Catena
Contains containerized catena service examples and associated IAC (e.g. helm charts, docker compose files)

## Quick Reference
- [Catena](https://github.com/rossvideo/Catena)
- [Report Issues](https://github.com/rossvideo/Catena/issues)
- [Github for this repo](https://github.com/rossvideo/Catena-deployments)

## Choosing an image
Every image is a Catena example device you can point a client at. Examples are built from two SDKs:

| | Go SDK (recommended) | C++ SDK |
|---|---|---|
| [Tag format](#supported-tags) | `go-<example>-dev` | `<example>-<transport>-dev` |
| Transports | gRPC and/or REST from the same image, chosen at runtime | One transport per image, fixed at build time |
| Ports | gRPC `6254`, REST `9080` | gRPC `6254`, REST `443` |
| Status | Newer, actively developed | Transport-specific builds |

**Not sure which to use?** Pick a Go image. One container can serve gRPC, REST or both, so it works for any client you're testing.

> [!NOTE]
> Go images start with **no transport enabled**. Set `CATENA_USE_GRPC=yes` and/or `CATENA_USE_REST=yes` (see [Go SDK images](#go-sdk-images)).

## Go SDK examples
<!-- GO_EXAMPLES_START -->
- hello-world
- one-of-everything
<!-- GO_EXAMPLES_END -->

## C++ SDK examples
<!-- EXAMPLES_START -->
### REST
- asset-request
- audiodeck
- audiodeck-JSON
- discovery
- one-of-everything
- simple-audiodeck-JSON
- status-update
- status-update-JSON
- use-commands
- use-menus
### gRPC
- audiodeck
- audiodeck-yaml
- external-object-request
- one-of-everything
- simple-dashboard-audiodeck
- status-update
- use-commands
- use-menus
<!-- EXAMPLES_END -->

## Supported tags
All images are published to `ghcr.io/rossvideo/catena`, one tag per example:

| SDK | Tag | Example |
|-----|-----|---------|
| Go | `go-<example>-dev` | `go-one-of-everything-dev` |
| C++ | `<example>-<transport>-dev` | `one-of-everything-gRPC-dev` |

Only development builds are published for now, so every tag ends in `-dev`, and each tag is overwritten whenever its example is rebuilt from the latest Catena source. The Catena version is listed in [examples.json](examples.json), and the source commit is recorded in the `com.rossvideo.catena.sha` image label.

## Docker Compose
See the [Docker Compose README](compose/README.md)

> [!NOTE]
> The compose `.env` is currently only set up for C++ SDK images.

### TL;DR
```
git clone https://github.com/rossvideo/Catena-deployments.git
cd Catena-deployments/compose
docker compose up -d
```

## Helm charts
For more information see the [Helm Charts README](helmcharts/README.md)

> [!NOTE]
> The Helm chart currently only supports C++ SDK images.

### TL;DR
```
helm repo add catena-deployments https://rossvideo.github.io/Catena-deployments
helm repo update
helm install --namespace catena --create-namespace --set image.develop=true catena catena-deployments/catena-helm
```

## How to use these images
Configuration is done with environment variables, all prefixed with `CATENA_`.

### Go SDK images
Tags are `go-<example>-dev`, for example `go-one-of-everything-dev`.

Serve both transports:
```
docker run --name catena -p 6254:6254 -p 9080:9080 \
  -e CATENA_USE_GRPC=yes -e CATENA_USE_REST=yes \
  ghcr.io/rossvideo/catena:go-one-of-everything-dev
```

Every option can also be passed as a command-line flag after the image name (e.g. `-use-grpc -use-rest`). Run `-help` to see the full list:
```
docker run --rm ghcr.io/rossvideo/catena:go-one-of-everything-dev -help
```

Common options:

| Variable | Default | Description |
|----------|---------|-------------|
| `CATENA_USE_GRPC` | off | Enable the gRPC transport. |
| `CATENA_USE_REST` | off | Enable the REST transport. |
| `CATENA_GRPC_PORT` | `6254` | Port the gRPC transport listens on. |
| `CATENA_REST_PORT` | `9080` | Port the REST transport listens on. |
| `CATENA_AUTHZ` | `true` | Enable authorization checks. Set to `false` to disable. |
| `CATENA_MAX_CONNECTIONS` | `100` | Maximum number of concurrent connections. |
| `CATENA_GRPC_REFLECTION` | off | Enable gRPC server reflection. |
| `CATENA_REST_ALLOWED_ORIGINS` | none | Comma-separated CORS allowed origins (`*` for any). |
| `CATENA_LOG_LEVEL` | `INFO` | Minimum log level to output. |

TLS (`CATENA_GRPC_TLS_*`, `CATENA_REST_TLS_*`), JWT (`CATENA_JWT_*`) and DashBoard (`CATENA_DASHBOARD_*`) settings are also available; see `-help`.

### C++ SDK images
Tags are `<example>-<transport>-dev`, for example `one-of-everything-gRPC-dev`. Each image serves only the transport in its name.

```
docker run --name catena -p 6254:6254 ghcr.io/rossvideo/catena:one-of-everything-gRPC-dev
```

| Variable | Description |
|----------|-------------|
| `CATENA_AUTHZ` | Set to enable authorization. |
| `CATENA_MAX_CONNECTIONS` | The maximum number of connections. |
| `CATENA_PORT` | The port the service listens on. 6254 is for gRPC and 443 is for REST. |
| `CATENA_STATIC_ROOT` | Override the static root directory for external objects. |