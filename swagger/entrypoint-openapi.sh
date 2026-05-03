#!/usr/bin/env sh
set -e

echo "[entrypoint-openapi] Starting OpenAPI update"

# Ensure python3 exists (defensive – Docker build already installs it)
if ! command -v python3 >/dev/null 2>&1; then
	echo "[entrypoint-openapi] python3 not found; attempting install"
	if command -v apk >/dev/null 2>&1; then
		apk add --no-cache python3 py3-pip || echo "[entrypoint-openapi] apk install failed"
	elif command -v apt-get >/dev/null 2>&1; then
		apt-get update && apt-get install -y python3 python3-pip || echo "[entrypoint-openapi] apt-get install failed"
	elif command -v yum >/dev/null 2>&1; then
		yum install -y python3 python3-pip || echo "[entrypoint-openapi] yum install failed"
	else
		echo "[entrypoint-openapi] No known package manager available; cannot install python3"
	fi
fi
echo "[entrypoint-openapi] python3 found/installed"
# Ensure dependencies (requests, PyYAML)
pip3 install --no-cache-dir -r /opt/requirements.txt --break-system-packages
echo "[entrypoint-openapi] Python dependencies installed"

export OUTPUT_PATH="/usr/share/nginx/html/openapi.yaml"
python3 /opt/openapi_update.py || echo "[entrypoint-openapi] Python script failed"

echo "[entrypoint-openapi] OpenAPI update complete"