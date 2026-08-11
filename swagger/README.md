# Swagger UI OpenAPI Mutation

This directory builds a Swagger UI container that downloads the upstream SMPTE ST2138 OpenAPI specification and mutates it at startup using a Python script (`openapi_update.py`).

## Startup Flow
1. Container entrypoint executes scripts in `/docker-entrypoint.d/`.
2. `10-openapi-update.sh` (from `entrypoint-openapi.sh`) runs `openapi_update.py`.
3. Script downloads the source spec and applies mutations:
   - Optionally replaces servers from `ST2138_URLS`
   - Optionally clears all upstream servers via `ST2138_REMOVE_URLS`
   - Appends servers from `ST2138_ADD_URLS`
   - Removes a blocked server (`https://device.catenamedia.tv:443/st2138-api/v1`)
   - Optionally strips existing security sections via `ST2138_REMOVE_SECURITY`
   - Optionally injects bearer auth if `ST2138_ADD_BEARER` is truthy
4. Result written to `/usr/share/nginx/html/openapi.yaml` which Swagger UI serves.

## Environment Variables
| Variable | Purpose | Example |
|----------|---------|---------|
| `ST2138_URLS` | JSON array replacing servers entirely | `[{"url":"https://foo","name":"Foo"}]` |
| `ST2138_ADD_URLS` | JSON array appended to the current server list | `[{"url":"https://bar","name":"Bar"}]` |
| `ST2138_REMOVE_URLS` | Truthy string clears upstream `servers` before other mutations | `true` |
| `ST2138_REMOVE_SECURITY` | Truthy string removes global security + security schemes | `true` |
| `ST2138_ADD_BEARER` | Truthy string adds `BearerAuth` scheme + global security | `true` |
| `SOURCE_URL` | Override source spec URL | `https://example.com/openapi.yaml` |
| `OUTPUT_PATH` | Destination path (override) | `/tmp/openapi.yaml` |

## Local Usage
Run the mutation locally and write `openapi.yaml` into this directory:

```bash
cd swagger
./run_update.sh
```

Customize servers:
```bash
export ST2138_URLS='[{"url":"https://api.example.com/v1","name":"example"}]'
./run_update.sh
```

Append servers and clear upstream defaults:
```bash
export ST2138_REMOVE_URLS=true
export ST2138_ADD_URLS='[{"url":"https://api.extra.com/v2","name":"extra"}]'
./run_update.sh
```

Add bearer auth after removing existing security:
```bash
export ST2138_REMOVE_SECURITY=true
export ST2138_ADD_BEARER=true
./run_update.sh
```

## Docker Build & Run
```bash
docker build -t catena-swagger-ui swagger/
docker run --rm -p 8080:8080 -e ST2138_URLS='[{"url":"https://api.example.com/v1","name":"example"}]' catena-swagger-ui
```

## Notes
The former shell script `sedstuff.sh` has been replaced by Python for clearer structured mutations (YAML manipulation instead of regex replacement). If needed, server removal logic is centralized in `openapi_update.py`.
