# Resto Platform - Deployment & Infrastructure Architecture

---

## 1. Local Development Topology

The local environment is orchestrated via Docker Compose:
- **PostgreSQL 17 (`postgres:17-alpine`):** Port 5432
- **Redis 7 (`redis:7-alpine`):** Port 6379
- **PgAdmin 4:** Port 5050
- **Go Backend (`restolink`):** Port 8080 (`go run cmd/api/main.go`)
- **SvelteKit Frontend (`restoview`):** Port 5173 (`npm run dev`)

---

## 2. Cloud Deployment Topology

```
[ DNS / CDN ]  Cloudflare (SSL Termination, DDoS mitigation, Edge Caching)
      │
      ▼
[ Reverse Proxy ]  Traefik / NGINX / Caddy (Dynamic host router for *.resto.com & custom domains)
      │
      ├───► restoview (Node.js Adapter / Docker container, Port 3000)
      │
      └───► restolink (Static Go Alpine Container, Port 8080)
                │
                ├───► Managed PostgreSQL 17 (AWS RDS / Supabase / Neon)
                └───► Managed Redis 7 (Upstash / AWS ElastiCache)
```

---

## 3. Production Docker Builds

- **`restolink` Multi-stage Dockerfile:**
  - Stage 1: `golang:1.23-alpine` compiles static binary `CGO_ENABLED=0 go build -ldflags="-w -s" -o /app/server cmd/api/main.go`.
  - Stage 2: `scratch` or `alpine:3.20` image with CA certificates (~25MB total image size).
- **`restoview` Multi-stage Dockerfile:**
  - Stage 1: `node:22-alpine` runs `npm ci && npm run build`.
  - Stage 2: `node:22-alpine` runs production server using `@sveltejs/adapter-node` (`node build`).
