#!/usr/bin/env python3
"""Protected read-only MinIO metadata wrapper.

The wrapper exposes browser-safe administrator metadata without exposing MinIO
root credentials, S3 signatures, object bodies, or bucket mutation operations.
"""

from __future__ import annotations

import json
import mimetypes
import os
import posixpath
import time
import urllib.error
import urllib.request
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse


ADMIN_ROLES = {
    "global:superadmin",
    "app:minio-microservice:admin",
    "internal:minio-microservice:admin",
}
DATA_ROOT = Path(os.environ.get("RECORDS_DATA_ROOT", "/data")).resolve()
BUCKET = os.environ.get("RECORDS_BUCKET", "speakasap-records").strip() or "speakasap-records"
AUTH_SERVICE_URL = os.environ.get("AUTH_SERVICE_URL", "http://auth-microservice.statex-apps.svc.cluster.local:3370").rstrip("/")
ALLOWED_ORIGIN = os.environ.get("ADMIN_API_ALLOWED_ORIGIN", "https://storage.alfares.cz")
MAX_LIST_LIMIT = int(os.environ.get("ADMIN_API_MAX_LIST_LIMIT", "200"))
MAX_SUMMARY_OBJECTS = int(os.environ.get("ADMIN_API_MAX_SUMMARY_OBJECTS", "100000"))


def _json_bytes(payload: dict[str, Any]) -> bytes:
    return json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")


def _bucket_root() -> Path:
    return (DATA_ROOT / BUCKET).resolve()


def _safe_prefix(raw_prefix: str) -> str:
    prefix = raw_prefix.strip().lstrip("/")
    normalized = posixpath.normpath(prefix) if prefix else ""
    if normalized in {"", "."}:
        return ""
    if normalized.startswith("../") or normalized == ".." or "/../" in normalized:
        raise ValueError("invalid prefix")
    if any(part.startswith(".") for part in normalized.split("/")):
        raise ValueError("hidden paths are not listable")
    return normalized.rstrip("/")


def _roles_from_auth(auth_payload: dict[str, Any]) -> set[str]:
    candidates = [
        auth_payload.get("roles"),
        auth_payload.get("user", {}).get("roles") if isinstance(auth_payload.get("user"), dict) else None,
        auth_payload.get("data", {}).get("roles") if isinstance(auth_payload.get("data"), dict) else None,
    ]
    roles: set[str] = set()
    for candidate in candidates:
        if isinstance(candidate, list):
            roles.update(str(role) for role in candidate)
    return roles


def _validate_token(token: str) -> dict[str, Any] | None:
    body = _json_bytes({"token": token})
    request = urllib.request.Request(
        f"{AUTH_SERVICE_URL}/auth/validate",
        data=body,
        method="POST",
        headers={"Content-Type": "application/json", "Content-Length": str(len(body))},
    )
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            if response.status != HTTPStatus.OK:
                return None
            return json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        return None


def _object_record(path: Path, root: Path) -> dict[str, Any]:
    stat = path.stat()
    key = path.relative_to(root).as_posix()
    content_type = mimetypes.guess_type(key)[0] or "application/octet-stream"
    return {
        "key": key,
        "size": stat.st_size,
        "lastModified": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(stat.st_mtime)),
        "contentType": content_type,
    }


def _iter_objects(prefix: str = ""):
    root = _bucket_root()
    scan_root = (root / prefix).resolve() if prefix else root
    if not root.exists() or not scan_root.exists():
        return
    if root not in [scan_root, *scan_root.parents]:
        raise ValueError("prefix escapes bucket root")
    for path in sorted(scan_root.rglob("*")):
        rel_parts = path.relative_to(root).parts
        if not path.is_file() or any(part.startswith(".") for part in rel_parts):
            continue
        yield path


def _summary() -> dict[str, Any]:
    count = 0
    total_size = 0
    newest: str | None = None
    truncated = False
    for path in _iter_objects():
        count += 1
        stat = path.stat()
        total_size += stat.st_size
        modified = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(stat.st_mtime))
        newest = modified if newest is None or modified > newest else newest
        if count >= MAX_SUMMARY_OBJECTS:
            truncated = True
            break
    return {
        "bucket": BUCKET,
        "objectCount": count,
        "totalBytes": total_size,
        "newestObjectModifiedAt": newest,
        "truncated": truncated,
    }


class Handler(BaseHTTPRequestHandler):
    server_version = "minio-admin-wrapper/1.0"

    def log_message(self, format: str, *args: Any) -> None:
        return

    def end_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", ALLOWED_ORIGIN)
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def _send_json(self, status: HTTPStatus, payload: dict[str, Any]) -> None:
        body = _json_bytes(payload)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _authorize(self) -> bool:
        header = self.headers.get("Authorization", "")
        if not header.startswith("Bearer "):
            self._send_json(HTTPStatus.UNAUTHORIZED, {"error": "missing_bearer_token"})
            return False
        auth_payload = _validate_token(header.removeprefix("Bearer ").strip())
        if not auth_payload:
            self._send_json(HTTPStatus.UNAUTHORIZED, {"error": "invalid_token"})
            return False
        if not (_roles_from_auth(auth_payload) & ADMIN_ROLES):
            self._send_json(HTTPStatus.FORBIDDEN, {"error": "admin_role_required"})
            return False
        return True

    def do_OPTIONS(self) -> None:
        self.send_response(HTTPStatus.NO_CONTENT)
        self.end_headers()

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/healthz":
            self._send_json(HTTPStatus.OK, {"status": "ok", "bucketConfigured": bool(BUCKET)})
            return
        if not parsed.path.startswith("/api/admin/"):
            self._send_json(HTTPStatus.NOT_FOUND, {"error": "not_found"})
            return
        if not self._authorize():
            return
        try:
            if parsed.path == "/api/admin/summary":
                self._send_json(HTTPStatus.OK, _summary())
                return
            if parsed.path == "/api/admin/objects":
                query = parse_qs(parsed.query)
                prefix = _safe_prefix(query.get("prefix", [""])[0])
                limit = min(max(int(query.get("limit", ["50"])[0]), 1), MAX_LIST_LIMIT)
                objects = []
                for path in _iter_objects(prefix):
                    objects.append(_object_record(path, _bucket_root()))
                    if len(objects) >= limit:
                        break
                self._send_json(HTTPStatus.OK, {"bucket": BUCKET, "prefix": prefix, "limit": limit, "objects": objects})
                return
        except (OSError, ValueError) as error:
            self._send_json(HTTPStatus.BAD_REQUEST, {"error": "metadata_unavailable", "detail": str(error)})
            return
        self._send_json(HTTPStatus.NOT_FOUND, {"error": "not_found"})


def main() -> None:
    port = int(os.environ.get("PORT", "8080"))
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()


if __name__ == "__main__":
    main()
