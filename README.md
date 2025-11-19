# Catena
Contains containerized catena service examples and associated IAC (e.g. helm charts, docker compose files)

## Quick Reference
- [Catena](https://github.com/rossvideo/Catena)
- [Report Issues](https://github.com/rossvideo/Catena/issues)
- [Github for this repo](https://github.com/rossvideo/Catena-deployments)

## List of examples
<!-- EXAMPLES_START -->
### gRPC
- audiodeck
- audiodeck-yaml
- external-object-request
- one-of-everything
- simple-dashboard-audiodeck
- status-update
- use-commands
- use-menus
### REST
- asset-request
- audiodeck
- audiodeck-JSON
- discovery
- one-of-everything
- status-update
- status-update-JSON
- use-commands
- use-menus
<!-- EXAMPLES_END -->

## Supported tags

TODO

## Docker Compose
See the [Docker Compose README](compose/README.md)

### TL;DR
```
git clone git@github.com/Catena-deployments
cd Catena-deployments/compose
docker compose up -d
```

## Helm charts
For more information see the [Helm Charts README](helmcharts/README.md)

### TL;DR
```
helm repo add catena-deployments https://rossvideo.github.io/Catena-deployments
helm install --namespace catena catena catena-deployments/catena
```

## How to use this image
There exists tags for everything example of the form <example>-<connection>. For example `one-of-everything-gRPC`.
### Simple run with defaults
```
docker run --name catena -p 6254:6254 ghcr.io/rossvideo/catena:one-of-everything-gRPC
```
### Configuration
Configuration can be changed by injecting environment variables. All variables are prefixed with `CATENA_`.

| Variable | Description |
|----------|-------------|
| `CATENA_AUTHZ` | Set to enable authorization. |
| `CATENA_MAX_CONNECTIONS` | The maximum number of connections. |
| `CATENA_PORT` | The port the service listens on. 6254 is for gRPC and 443 is for REST. |
| `CATENA_STATIC_ROOT` | Override the static root directory for external objects. |