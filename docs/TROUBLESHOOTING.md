# Resto Platform - Troubleshooting & Operational Diagnostics

---

## 1. Common Issues & Resolutions

### 1.1 "Connection Refused on Port 5432 or 6379"
- **Cause:** Docker database containers are not running.
- **Resolution:**
  ```bash
  docker compose up -d postgres redis
  docker compose ps
  ```

### 1.2 "Tenant Not Found (404)"
- **Cause:** Missing `X-Tenant-Slug` header or host does not match any tenant slug or custom domain.
- **Resolution:** Ensure `X-Tenant-Slug: test-resto` is passed in request headers or test with `?tenant=test-resto`.

### 1.3 "WebSocket Connection Failed"
- **Cause:** API server not reachable at `ws://localhost:8080/ws` or CORS origins rejecting browser origin.
- **Resolution:** Check `CORS_ORIGINS` in `.env` and verify `restolink` is listening on port 8080.
