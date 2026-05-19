# Rubric — API / Backend (gated)

**Triggers:** changes under `apps/*api*/`, `services/*/src/`, route handlers, controllers, GraphQL schemas / resolvers, REST handlers, OpenAPI specs, worker job handlers.

Skip if no changed files match.

---

## Blockers

### Breaking contract change

- A field removed or renamed in a response shape that external callers depend on.
- A required input field added (existing callers will now 400).
- An HTTP status code change that callers branch on (e.g., 200 → 204, 201 → 200).
- A GraphQL type non-nullable → nullable (or vice versa) on a queried field.

### Unbounded GraphQL payload

```graphql
# BLOCK — no pagination, nested arrays can be huge
query {
  accounts {
    users {
      deliveries {
        stops { items }
      }
    }
  }
}
```

Flag resolvers returning arrays without a limit, and nested relationships without depth limiting.

### Missing authn / authz on a new endpoint

A new route added without a clear auth check (middleware, `requireAuth`, decorator). Flag even if the test suite passes — the auth middleware needs to be wired explicitly.

### Worker job that doesn't ack / retry safely

- A job handler that mutates external state and then `throws`, with no idempotency check on retry.
- A handler that swallows errors silently and `acks` (job lost).

---

## High

### Error response shape inconsistency

If the codebase has a standard error envelope and this new endpoint returns a bare string or a different shape, flag.

### Missing input validation at a system boundary

External-facing endpoint that trusts the request body's types without parsing through Zod / Joi / class-validator (or whatever the project uses).

### Missing rate limiting on an expensive endpoint

A new endpoint that triggers external API calls, large queries, or LLM calls — with no rate limit.

### Long-running sync work in a request handler

Work that should be offloaded to a worker / queue is happening inline in the response path.

---

## Medium

- New endpoint without observability (no log line at the boundary, no metric).
- Job handler entry point doing too much; logic should be extracted into private helpers (Alex's CONVENTIONS).
- Parallel I/O opportunities missed: independent awaits chained sequentially when `Promise.all` would do.

---

## Do NOT flag

- HTTP status code preferences (200 vs 204) when the codebase is inconsistent and there's no rule.
- Adding optional fields to a response (purely additive).
- Removing fields that are clearly internal / never had external consumers.
- "Should this be a worker job?" speculation on small synchronous work.

---

## Voice

Be specific about *who* breaks. "This breaks the mobile app's `/v1/deliveries` consumer" is useful; "this is a breaking change" is not.
