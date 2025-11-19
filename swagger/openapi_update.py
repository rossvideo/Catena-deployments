#!/usr/bin/env python3
"""Fetch and mutate the ST2138 OpenAPI spec.

Steps:
1. Download source spec from SMPTE GitHub.
2. Optionally replace servers from env ST2138_URLS (JSON array of {url,name}).
3. Optionally clear existing servers (ST2138_REMOVE_URLS=true) before handling
    replacements or additions (ST2138_ADD_URLS).
4. Remove any server matching BLOCKED_SERVER_URL.
5. Optionally drop existing security definitions (ST2138_REMOVE_SECURITY=true).
6. Optionally inject bearer auth (env ST2138_ADD_BEARER=true/1).
7. Write result to OUTPUT_PATH (default /usr/share/nginx/html/openapi.yaml).

Environment Variables:
    ST2138_URLS           JSON array e.g. [{"url":"https://...","name":"desc"},...]
    ST2138_ADD_URLS       JSON array appended after replacement/removal logic.
    ST2138_REMOVE_URLS    truthy string clears existing servers before applying
                                                replacements/additions.
    ST2138_REMOVE_SECURITY truthy string removes global security + security schemes.
    ST2138_ADD_BEARER     truthy string adds securitySchemes + global security requirement.
  OUTPUT_PATH           Destination path (default /usr/share/nginx/html/openapi.yaml)
  SOURCE_URL            Override source spec URL.

Exit codes:
  0 success
  1 network/spec download failure
    2 YAML parse failure
    3 Server list environment invalid JSON
"""

from __future__ import annotations

import json
import os
import sys
from typing import List, Dict, Any, Set

import requests
import yaml

DEFAULT_SOURCE_URL = "https://smpte.github.io/st2138-a/docs/openapi.yaml"
BLOCKED_SERVER_URL = "https://device.catenamedia.tv:443/st2138-api/v1"


def log(msg: str) -> None:
    print(f"[openapi_update] {msg}", flush=True)


def fetch_spec(url: str) -> str:
    log(f"Downloading OpenAPI spec from {url}")
    try:
        resp = requests.get(url, timeout=30)
    except requests.RequestException as e:
        log(f"ERROR: network error fetching spec: {e}")
        sys.exit(1)
    if resp.status_code != 200:
        log(f"ERROR: unexpected status {resp.status_code}")
        sys.exit(1)
    return resp.text


def parse_yaml(text: str) -> Dict[str, Any]:
    try:
        return yaml.safe_load(text)
    except yaml.YAMLError as e:
        log(f"ERROR: YAML parse failed: {e}")
        sys.exit(2)


TRUTHY = {"1", "true", "yes", "on"}


def env_truthy(name: str) -> bool:
    value = os.getenv(name)
    if value is None:
        return False
    return value.strip().lower() in TRUTHY


def load_servers_env(var_name: str) -> List[Dict[str, str]]:
    raw = os.getenv(var_name)
    if not raw:
        return []
    log(f"Processing {var_name} env")
    try:
        servers = json.loads(raw)
    except json.JSONDecodeError as e:
        log(f"ERROR: {var_name} invalid JSON: {e}")
        sys.exit(3)
    if not isinstance(servers, list):
        log(f"ERROR: {var_name} must be a JSON array")
        sys.exit(3)
    cleaned = []
    for entry in servers:
        if not isinstance(entry, dict):
            continue
        url = entry.get("url")
        name = entry.get("name") or entry.get("description") or ""
        if url:
            cleaned.append({"url": url, "description": name})
            log(f"Added server from {var_name}: url={url} description={name}")
    return cleaned


def apply_server_mutations(
    spec: Dict[str, Any],
    replacement_servers: List[Dict[str, str]],
    additional_servers: List[Dict[str, str]],
    remove_all: bool,
) -> None:
    servers = spec.get("servers")
    if not isinstance(servers, list):
        servers = []

    if remove_all:
        if servers:
            log("Clearing existing servers due to ST2138_REMOVE_URLS")
        servers = []

    if replacement_servers:
        servers = replacement_servers
        log(f"Replaced servers with {len(replacement_servers)} entries from ST2138_URLS")

    if additional_servers:
        seen_urls: Set[str] = {
            s.get("url")
            for s in servers
            if isinstance(s, dict) and s.get("url")
        }
        appended = 0
        for server in additional_servers:
            url = server.get("url")
            if url and url not in seen_urls:
                servers.append(server)
                seen_urls.add(url)
                appended += 1
        if appended:
            log(f"Appended {appended} server(s) from ST2138_ADD_URLS")

    filtered = [s for s in servers if isinstance(s, dict)]
    filtered = [s for s in filtered if s.get("url") != BLOCKED_SERVER_URL]
    if len(filtered) != len(servers):
        log(f"Removed blocked server {BLOCKED_SERVER_URL}")

    spec["servers"] = filtered


def remove_security_blocks(spec: Dict[str, Any]) -> None:
    if not env_truthy("ST2138_REMOVE_SECURITY"):
        return

    removed_any = False

    if "security" in spec:
        spec.pop("security", None)
        log("Removed global security section")
        removed_any = True

    components = spec.get("components")
    if isinstance(components, dict) and "securitySchemes" in components:
        components.pop("securitySchemes", None)
        log("Removed components.securitySchemes")
        removed_any = True

    if not removed_any:
        log("ST2138_REMOVE_SECURITY set but no security blocks were present")


def add_bearer_auth(spec: Dict[str, Any]) -> None:
    if not env_truthy("ST2138_ADD_BEARER"):
        return
    components = spec.setdefault("components", {})
    security_schemes = components.setdefault("securitySchemes", {})
    if "BearerAuth" not in security_schemes:
        security_schemes["BearerAuth"] = {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT"
        }
        log("Injected components.securitySchemes.BearerAuth")
    # Global security requirement
    security = spec.setdefault("security", [])
    if not any("BearerAuth" in item for item in security if isinstance(item, dict)):
        security.append({"BearerAuth": []})
        log("Added global security requirement BearerAuth")


def write_spec(spec: Dict[str, Any], path: str) -> None:
    log(f"Writing mutated spec to {path}")
    with open(path, "w", encoding="utf-8") as f:
        yaml.safe_dump(spec, f, sort_keys=False)


def main() -> None:
    source_url = os.getenv("SOURCE_URL", DEFAULT_SOURCE_URL)
    output_path = os.getenv("OUTPUT_PATH", "/usr/share/nginx/html/openapi.yaml")
    text = fetch_spec(source_url)
    spec = parse_yaml(text)
    replacement_servers = load_servers_env("ST2138_URLS")
    additional_servers = load_servers_env("ST2138_ADD_URLS")
    remove_all = env_truthy("ST2138_REMOVE_URLS")
    apply_server_mutations(spec, replacement_servers, additional_servers, remove_all)
    remove_security_blocks(spec)
    add_bearer_auth(spec)
    write_spec(spec, output_path)
    log("Update complete")


if __name__ == "__main__":
    main()
