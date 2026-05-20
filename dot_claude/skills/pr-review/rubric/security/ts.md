# Rubric — Security (TypeScript / JavaScript / Node)

Loaded when the diff touches `.ts` / `.tsx` / `.js` / `.jsx` / `.mjs` / `.cjs`. Builds on [_shared.md](_shared.md).

---

## Blockers

### `eval` / `new Function(...)` over caller-controlled input

```ts
// BLOCK
eval(req.body.expression);
const fn = new Function("payload", req.query.code);
```

### `dangerouslySetInnerHTML` with unsanitized input

```tsx
// BLOCK
<div dangerouslySetInnerHTML={{ __html: untrustedHtml }} />
```

Only OK if the source is provably static or has gone through a sanitizer (DOMPurify, etc.) with the result type-narrowed.

### Shell-string `exec` / `spawn` interpolating user input

```ts
// BLOCK
import { exec } from "node:child_process";
exec(`git log ${branch}`);

// OK
import { execFile } from "node:child_process";
execFile("git", ["log", branch]);
```

`exec` invokes a shell. Switch to `execFile` / `spawn` with an args array.

### SQL injection via raw query string

```ts
// BLOCK
prisma.$queryRawUnsafe(`SELECT * FROM users WHERE email = '${email}'`);
db.query(`SELECT * FROM orders WHERE id = ${orderId}`);

// OK — Prisma tagged template
prisma.$queryRaw`SELECT * FROM users WHERE email = ${email}`;
// OK — parameterized
db.query("SELECT * FROM orders WHERE id = $1", [orderId]);
```

### SSRF via `fetch` / `axios` / `got` on user-provided URLs

```ts
// BLOCK in a server handler
const res = await fetch(req.body.url);
const res = await axios.get(req.query.target);
```

OK only when the URL is parsed and the host validated against an allowlist before the request.

---

## High

### `JSON.parse` on untrusted input without a try/catch

A crash in a request handler is a denial-of-service primitive when triggered intentionally.

### Prototype pollution sinks

- `Object.assign({}, userInput)` deep-merged into a config / options object that's later passed to a sensitive function.
- `lodash.merge` / `lodash.set` with user-controlled paths.

### Weak crypto primitives

- `crypto.createHash("md5"|"sha1")` for anything other than legacy fingerprinting.
- `Math.random()` used for tokens, IDs, or anything security-sensitive (use `crypto.randomBytes` / `crypto.randomUUID`).
- `crypto.timingSafeEqual` *not* used when comparing secrets / HMACs.

### Cookies / sessions configured insecurely

- `httpOnly: false` on a session cookie.
- `sameSite: "none"` without `secure: true`.
- New session set with no `maxAge` / no expiry.

---

## Medium

- `setTimeout` / `setInterval` with a string argument (acts like `eval`).
- `JSON.stringify` of an error object that doesn't serialize `.message` / `.stack` (silent info loss in logs).
- `process.env` read at module top-level when the variable might not be set yet — masks deployment misconfig.

---

## Do NOT flag

- Type-only imports referencing `crypto` / `child_process`.
- `eval`-like patterns inside `*.test.*` or fixture files.
- Generic "use HTTPS" / "add CSP headers" without a specific code site.
- TypeScript `as` casts — those are correctness, not security, unless they cross a trust boundary.
