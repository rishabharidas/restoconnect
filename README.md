# restoconnect - Resto Platform Orchestrator & Monorepo

`restoconnect` is the central orchestration repository for the **Resto Platform**, a multi-tenant Restaurant Operating System. It houses the frontend (`restoview`), the backend API (`restolink`), local development container services, and automated database bootstrapping.

---

## Workspace Structure

```
restoconnect/
├── restoview/              # SvelteKit 5 Universal PWA (Customer QR, Waiter POS, KDS, Driver Tracker)
├── restolink/              # REST & Realtime Backend API
├── init-db/                # Automated DB init scripts
│   └── 01-init.sql         # Multi-tenant schema, enums, tables & seed data
├── docker-compose.yaml     # Local PostgreSQL 17, Redis 7 & PgAdmin
├── .env.example            # Environment variable template
├── AGENTS.md               # Architecture and guidelines for developers & AI agents
└── README.md
```

---

## Quickstart

### 1. Environment Setup
```bash
cp .env.example .env
```

### 2. Start PostgreSQL & Redis
```bash
docker compose up -d postgres redis
```
*Note: The database automatically runs `init-db/01-init.sql` on first launch, creating all schemas, enums, tables, and demo seed data.*

### 3. Run Frontend (`restoview`)
```bash
cd restoview
npm install
npm run dev
```

### 4. Run Backend (`restolink`)
```bash
cd restolink
# See restolink/MIGRATION_GUIDE.md and restolink/API_SPEC.md
```

---

## Key Guides

- **Architecture & Agents Guide:** [`AGENTS.md`](./AGENTS.md)
- **API Endpoints & WebSocket Specs:** [`restolink/API_SPEC.md`](./restolink/API_SPEC.md)
- **Node.js / Go Backend Migration Guide:** [`restolink/MIGRATION_GUIDE.md`](./restolink/MIGRATION_GUIDE.md)
