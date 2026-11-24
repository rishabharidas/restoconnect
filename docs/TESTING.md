# Resto Platform - Quality Assurance & Testing Standards

---

## 1. Testing Pyramid Strategy

```
         / \
        /   \     E2E Tests (Playwright)
       /  5% \    Simulate customer QR scan → KDS advance → bill
      /───────\
     /         \   Integration Tests
    /    25%    \  PostgreSQL & Redis API endpoints
   /─────────────\
  /               \ Unit Tests (Go & Vitest)
 /       70%       \ Pricing, GST tax, State Machine, Stores
/───────────────────\
```

---

## 2. Test Execution Commands

### Frontend Unit Tests
```bash
cd restoview
npm run test:unit -- --run
```

### Frontend Typecheck & Lint
```bash
cd restoview
npm run check
npm run lint
```

### Backend Unit & Integration Tests
```bash
cd restolink
go test -v ./...
```

### Full End-to-End Suite
```bash
cd restoview
npm run test:e2e
```
