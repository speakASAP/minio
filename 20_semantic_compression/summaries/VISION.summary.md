# VISION Summary

```yaml
source_document: ../../01_vision/VISION.md
compression_level: summary
last_updated: 2026-06-13
compression_owner: ai-draft
fidelity_status: draft
must_read_full_document_when:
  - changing storage, access, proxy, CORS, bucket, or credential behavior
```

Private MinIO storage for recordings and artifacts. No anonymous read. Reads use authentication or presigned URLs. Preserve lesson key layout, credential secrecy, SigV4 proxy behavior, and validation gates.
