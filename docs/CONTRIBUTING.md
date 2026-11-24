# Resto Platform - Contributing & Developer Onboarding Guide

---

## 1. Workspace Quickstart

```bash
# 1. Start Database & Cache
docker compose up -d postgres redis

# 2. Run Backend API
cd restolink
go run cmd/api/main.go

# 3. Run Frontend Application
cd restoview
npm install
npm run dev
```

---

## 2. Commit & Code Quality Standards

Before committing changes:
1. `npm run check` in `restoview` must find 0 errors.
2. `npm run test:unit -- --run` in `restoview` must pass.
3. `go test ./...` in `restolink` must pass.
4. `go vet ./...` in `restolink` must pass.
5. All new database modifications must be accompanied by a versioned migration in `migrations/`.
