# Rubric — Security (always-on)

Runs on every PR. Overlays can tighten thresholds or add JWT tables, secret allowlists, etc.

---

## Blockers

### Hardcoded secrets

```ts
// BLOCK
const API_KEY = "sk_live_abc123xyz";
const conn = "postgres://user:pass@host/db";

// OK
const API_KEY = process.env.API_KEY;
```

Look for: API keys, tokens, passwords, connection strings with embedded credentials, private keys, AWS access keys, OAuth client secrets.

**Not a secret** (do not flag): `$VAR`, `${VAR}`, `process.env.X`, `${{ secrets.* }}`, references to a secret manager, git credential helpers, mocked test fixtures clearly under a `__fixtures__` or `*.test.*` path.

### Injection vectors

- String concatenation building SQL outside an ORM (raw `db.query("SELECT … " + userId)`).
- `exec` / `spawn` with shell strings interpolating user input.
- `dangerouslySetInnerHTML` with unsanitized input.
- `eval`, `new Function(...)` over caller-controlled strings.

### Authn / authz changes

- A route handler that previously required auth now doesn't.
- A permission check removed, weakened, or short-circuited.
- A role/permission constant changed (e.g. `admin` → `user`) on an existing endpoint.

### Verification weakened

- Removed signature verification.
- `ignoreExpiration: true` added to a JWT verify call.
- Catch block that swallows a verification error and continues.

### Unsafe deserialization / SSRF

- `JSON.parse` on attacker-controlled input feeding into a constructor / dynamic require.
- `fetch(userProvidedUrl)` without an allowlist or URL validation.
- `axios.get(req.body.url)` patterns inside server-side handlers.

---

## High

- New endpoint exposing PII without logging context or rate-limiting.
- Sensitive values (tokens, passwords, full PII rows) written to logs.
- CORS widened (`*` added, credentials enabled with `*`).
- Cryptographic primitives downgraded (HS256 → none, SHA-1 added).

---

## Do NOT flag

- Code that **reads / verifies** secrets via `process.env` — that's the right pattern.
- JWT verify / decode that doesn't change payload shape.
- Refactors that move security code without changing semantics.
- Hardcoded test fixtures in `*.test.*` / `__fixtures__` / `__mocks__` paths.
- "What if an attacker did X" speculation without a concrete code path.
- Generic "consider adding input validation" without a specific missing check.

---

## Voice on posted security findings

Be precise about the failure mode. "This logs the raw bearer token at L42" is useful; "this could leak credentials" is not. If you can't name the attacker model in one sentence, the finding is probably speculation — drop it.
