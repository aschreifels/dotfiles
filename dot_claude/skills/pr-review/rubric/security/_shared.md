# Rubric — Security (shared, language-agnostic)

Always loaded for any PR. Language-specific patterns live in sibling files (`ts.md`, `py.md`, etc.) and are loaded when the diff touches those languages.

---

## Blockers

### Hardcoded secrets

Look for committed API keys, tokens, passwords, connection strings with embedded credentials, private keys, AWS access keys, OAuth client secrets — in any file type.

```
// BLOCK
const API_KEY = "sk_live_EXAMPLE_DO_NOT_USE";
const conn   = "postgres://user:pass@host/db";
```

**Not a secret** (do not flag):

- `$VAR`, `${VAR}`, env-var indirection
- Secret-manager references (Puff, AWS Secrets Manager, Vault, etc.)
- `${{ secrets.* }}` (GitHub Actions)
- Git credential helpers referencing env vars
- Values clearly under `__fixtures__/`, `*.test.*`, `__mocks__/`, or other test-only paths

### Authn / authz changes

- A route handler that previously required auth now doesn't.
- A permission check removed, weakened, or short-circuited.
- A role/permission constant changed (e.g. `admin` → `user`) on an existing endpoint.
- New endpoint without an auth check, when the surrounding endpoints all have one.

### SSRF — server-side request forgery

A backend request whose URL is derived from caller-controlled input without an allowlist or URL validator. Cross-language pattern; the *call* differs (`fetch`, `requests.get`, `http.Get`, etc.) but the smell is the same.

### Verification weakened

- Removed signature/HMAC verification.
- Expiration check bypassed (`ignoreExpiration: true`, `verify_exp=False`, etc.).
- Catch block that swallows a verification error and continues.

### Sensitive data in logs / responses

Tokens, passwords, full PII rows (SSN, full PAN, etc.) appearing in `logger.*`, response bodies, or error messages.

---

## High

- New endpoint exposing PII without rate-limiting.
- CORS widened to `*` (especially with credentials enabled).
- Cryptographic primitives downgraded (HMAC removed, SHA-1 introduced, RSA key size reduced).
- Webhook handler that doesn't verify the source signature.

---

## Do NOT flag

- Code that *reads* secrets via the right indirection (`process.env`, `os.environ`, secret manager, etc.) — that's the right pattern.
- Refactors that move security code without changing semantics.
- Mocked credentials/tokens in tests under test paths.
- "What if an attacker did X" speculation without a concrete code path.
- Generic "consider adding input validation" without naming a specific missing check.

---

## Voice on posted security findings

Name the failure mode precisely. "This logs the raw bearer token at L42" is useful; "this could leak credentials" is not. If you can't state the attacker model in one sentence, the finding is likely speculation — drop it.
