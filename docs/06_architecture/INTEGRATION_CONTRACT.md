# Integration Contract
## Purpose
Describe deliberate ecosystem boundaries for private MinIO storage.
## Capability Decisions
`ips-adoption.json` holds all decisions. The wrapper requires auth-microservice token validation and logging-microservice structured logging; docs-RAG and monitoring are required.
## Data Ownership
MinIO owns object bytes and metadata. speakasap-portal owns lesson workflows; runlayer owns task-artifact workflows.
## Authentication and Authorization
S3 credentials are managed outside Git. Admin metadata needs a bearer token validated by auth-microservice; anonymous reads are forbidden.
## Synchronous Dependencies
The wrapper calls AUTH_SERVICE_URL and posts to LOGGING_SERVICE_URL at LOGGING_SERVICE_API_PATH.
## Asynchronous Dependencies
No RabbitMQ events are consumed or published.
## Degraded Operation
Failed auth validation denies privileged requests. Unhealthy pods fail probes; logging failure does not disclose secrets or make a failed operation successful.
## Validation
Inspect health probes and sanitized auth/logging tests; validate S3 signatures after proxy, CORS, endpoint, or bucket-policy changes.
