---
name: curri
description: Curri monorepo (teamcurri/curri) — Prisma scoping, JWT types, dangerous migrations, secret allowlist, project-name conventions.
applies_when:
  repo: teamcurri/curri
  file_exists: agent_docs/08-review-rules.md
---

# Overlay — Curri

Augments the universal rubric for the `teamcurri/curri` monorepo. All citations point at `agent_docs/08-review-rules.md` (the canonical in-repo source) and `AGENTS.md`.

When citing in a posted comment, link the source file with the head commit's full SHA.

---

## Augments: [security.md](../rubric/security.md)

### Blocker — Hardcoded secret (Curri allowlist)

Not a secret, do **not** flag:

- `$GH_TOKEN`, `${GH_TOKEN}`
- `process.env.X` of any kind
- `${{ secrets.* }}` (GitHub Actions)
- Git credential helpers referencing env vars
- Values clearly under `__fixtures__/`, `*.test.*`, or `__mocks__/`

Source: `agent_docs/08-review-rules.md` § "Hardcoded Secrets".

### Blocker — JWT structure change (security-review required)

**Known JWT types** (do NOT flag if unchanged):

| Type | Payload | Signing | Expiry |
|------|---------|---------|--------|
| User | `{ sub: "<email>" }` | `JWT_SIGNING_SECRET` | — |
| Driver | `{ externalId, firstName, lastName, phoneNumber }` | `JWT_SIGNING_SECRET` | — |
| Bidding | `{ driverId, firstName, lastName, phoneNumber }` | `JWT_SIGNING_SECRET` | 1h |
| Route Planner Driver | `{ driverId, firstName, itineraryExternalId, lastName, phoneNumber }` | `JWT_SIGNING_SECRET` | 24h |
| Impersonation | `{ adminEmail, userEmail }` | `JWT_SIGNING_SECRET` | 5s |
| Metabase Embed | `{ exp, params, resource }` | Metabase secret | — |
| DoorDash API | `{ aud, exp, iat, iss, kid }` | DoorDash secret (HS256) | — |

**Must flag** as Blocker:

1. New JWT type — any new `jwt.sign()` call with a payload shape not in the table above.
2. Payload modification — adding, removing, or renaming fields in an existing JWT type.
3. Signing config change — algorithm, secret, audience, issuer change.
4. Verification weakened — removed verify, `ignoreExpiration: true`, swallowed verification errors.

**Do NOT flag:**

- Code that reads / decodes / verifies a JWT without changing payload.
- Refactors that move JWT code without changing semantics.
- Expiration-time-only changes (note in summary, but not a Blocker).
- Mocked JWTs in tests.

Source: `agent_docs/08-review-rules.md` § "JWT Structure Changes".

---

## Augments: [db.md](../rubric/db.md)

### Blocker — Direct Prisma client outside `@curri/db`

```ts
// BLOCK
import { PrismaClient } from '@prisma/client';
import prisma from '@prisma/client';

// OK
import { prisma } from '@curri/db';
```

Exceptions (do **not** flag):

- Files inside `packages/curri-db/`.
- Type-only imports: `import type { Prisma } from '@prisma/client'`.
- Prisma migration files under `packages/curri-db/prisma/migrations/`.

Source: `agent_docs/08-review-rules.md` § "Direct Prisma Client Usage Outside @curri/db".

### Blocker — Dangerous migration (Curri specifics)

Inherit the universal table from `rubric/db.md`. In addition:

- All Curri migrations live in `packages/curri-db/prisma/migrations/`. Migrations outside that directory are themselves a Blocker.
- PR title must include `#manualdeploy` when a migration is present (see [AGENTS.md](../../AGENTS.md) "Critical Rules"). If the migration lands under `#autodeploy`, that's a Blocker.

### Blocker — Unbounded GraphQL payload

```graphql
# BLOCK — no pagination, nested arrays can be huge
query { accounts { users { deliveries { stops { items } } } } }
```

Flag resolvers returning arrays without limit, and nested relationships without depth limiting.

Source: `agent_docs/08-review-rules.md` § "Unbounded GraphQL Payloads".

### Blocker — Complex query without EXPLAIN ANALYZE

Per the universal `db.md` rule, escalated by Curri:

- Curri PR descriptions are **expected** to include `EXPLAIN ANALYZE` output for complex queries. Missing → at least `H` (request), and a Blocker if the query hits a known-large table (deliveries, orders, stops, telemetry).
- Red flags in the included plan (Blocker): `Seq Scan` on > 10K-row table, estimate vs actual off by 10×+, > 1s execution, > 1000-iter nested loops, on-disk sort.

Source: `agent_docs/08-review-rules.md` § "Complex Queries Without EXPLAIN ANALYZE".

---

## Augments: [conventions.md](../rubric/conventions.md)

### High — Project-name scope violation

All Curri Rush projects use the `@curri/` scope (e.g., `@curri/db`, `@curri/api`). New packages or imports that use a different scope are a High unless explicitly excepted (mobile apps, which aren't Rush-managed).

Source: [AGENTS.md](../../AGENTS.md) § "Critical Rules" #4.

### High — Direct `sops` usage

Per `AGENTS.md`: "Never use `sops` directly — use Puff CLI for secrets." A new shell-out to `sops` is a High.

### Blocker — PR title missing `#autodeploy` / `#manualdeploy`

Per `AGENTS.md` "Critical Rules" #2, every PR title must include `#autodeploy` (or `#manualdeploy` for migrations). If you can read the PR title and it's missing both tags, flag as a Blocker in the review summary (not a numbered finding — it's a metadata problem, not a code problem).

### High — Log-level misuse (Curri specifics)

Curri uses pino. New `logger.error(...)` calls for expected business outcomes (no rows found, validation rejected, etc.) should be `logger.warn`. Always include relevant IDs (`deliveryId`, `jobId`, `userId`) — the universal `correctness.md` rule applies, but cite `~/.config/ai/CONVENTIONS.md` § "Error Handling" when posted.

---

## Augments: [tests.md](../rubric/tests.md)

### Blocker — Integration test mocks the DB

Per `~/.config/ai/CONVENTIONS.md` (feedback memory): "integration tests must hit a real database, not mocks." If a new integration-style test mocks Prisma / the DB, flag.

Local docker services are available via `rush docker:services:start` — there's no excuse for mocking in integration scope.

### High — Bug fix without a failing-test-first

If the PR is tagged or described as a bug fix and there's no test that fails before the fix, flag. Curri has test infrastructure for ~every package — the "no infra" exception almost never applies.

---

## Curri-specific false positives

In addition to the universal list:

- **Generated files** under `**/generated/`, `**/__generated__/`, `prisma/client/` — never flag content; if the generator config changed, flag *that* instead.
- **Codegen output** committed for build determinism (GraphQL schema artifacts, etc.) — skip.
- **Lockfile changes** (`pnpm-lock.yaml`, `rush.json` dependency bumps) — not findings unless the bump is to a security-critical package.
- **Migration up files that "look scary" but operate on small/new tables** — verify the table size before promoting to Blocker; new tables are fine.

---

## Voice for posted Curri comments

When citing the in-repo rule, prefer a permalink to the section header:

```
agent_docs/08-review-rules.md § "Direct Prisma Client Usage Outside @curri/db"
```

Not:

```
You should use @curri/db.
```

The PR description / branch convention is `as/TICKET-ID_kebab-title` — if the PR's reviewer is curious about ticket context, the branch name tells them where to look in Linear.
