# Rubric — Database (gated)

**Triggers:** changes under `prisma/`, `*.prisma`, `*.sql`, `*/migrations/*`, files that import a Prisma client or raw SQL helpers, files containing `findMany` / `$queryRaw` / `$executeRaw`.

If none of the changed files match these triggers, skip this pack.

---

## Blockers

### N+1 queries (always block)

```ts
// BLOCK — query inside a loop
for (const user of users) {
  const orders = await db.orders.findMany({ where: { userId: user.id } });
}

// BLOCK — same problem, just concurrent
await Promise.all(users.map(u => db.orders.findMany({ where: { userId: u.id } })));

// OK — single batched query
const orders = await db.orders.findMany({
  where: { userId: { in: users.map(u => u.id) } }
});
```

Pattern recognition:

- `await` inside a `for` / `for...of` / `while` loop hitting the DB.
- `Promise.all(items.map(async ... db.something))` — still N queries.
- Recursive descent: outer query returns N rows, then an inner query per row.

### Unbounded `findMany`

```ts
// BLOCK on a table that can grow large
await prisma.deliveries.findMany();

// OK
await prisma.deliveries.findMany({
  where: { createdAt: { gte: lastWeek } },
  take: 1000,
});
```

If you can't tell whether the table is "large", default to flagging — the cost of a false positive here is one polite Q.

### Dangerous migration patterns

| Pattern | Verdict |
|---------|---------|
| `CREATE INDEX idx ON large_table (col)` (no `CONCURRENTLY`) | Blocker — locks writes |
| `CREATE INDEX CONCURRENTLY idx ON large_table (col)` (no `IF NOT EXISTS`) | High — not idempotent on retry |
| `CREATE INDEX CONCURRENTLY IF NOT EXISTS idx ON large_table (col)` | OK |
| `ALTER TABLE … ADD COLUMN … NOT NULL` (no default) | Blocker — full table scan |
| `ALTER COLUMN TYPE` on a large table | Blocker — full table + index rewrite |
| `DROP TABLE` / `DROP COLUMN` on table > 1M rows | Blocker — data loss without confirmation |
| `TRUNCATE` on production tables | Blocker — irreversible |
| > 5 new indices in one migration | High — review batch impact |

Exception: indexes on a table created in the same migration don't need `CONCURRENTLY`.

### Complex query without `EXPLAIN ANALYZE` evidence

A "complex" query is:

- JOINs across 3+ tables, **or**
- Subqueries / CTEs, **or**
- Query on a > 100K-row table without obvious index use, **or**
- Aggregations on large datasets, **or**
- Raw SQL via `$queryRaw` / `$executeRaw`.

If the PR description doesn't include `EXPLAIN ANALYZE` output for a complex query: **High** (request as a `Q`).

`EXPLAIN ANALYZE` red flags that **must** Block:

- `Seq Scan` on tables with > 10K rows.
- Row estimate vs actual differs by 10x or more.
- Execution > 1s for non-batch queries.
- Nested loops with > 1000 iterations.
- Sort operations spilling to disk.

---

## High

### Missing transaction on dependent writes

Two or more writes that must succeed together (or fail together) with no wrapping `$transaction` / `BEGIN…COMMIT`.

### Missing index for a new WHERE / ORDER BY

A new query that filters or sorts on columns with no covering index — flag with a suggested migration.

### Implicit cascade you didn't mean

`onDelete: Cascade` added to a relation pointing at a large table — flag and verify it's intentional.

---

## Medium

- Using `findMany` followed by `.length` to count instead of `count()`.
- Selecting `*` (no `select` / `include`) on a fat row when only a few fields are used.
- Multiple `findUnique` calls that could be one `findMany` with `where: { id: { in: [...] } }`.

---

## Do NOT flag

- N+1 patterns that the existing code *already* had on lines the PR didn't touch.
- Migrations that only add columns *with* a default and *to small/new tables*.
- `findMany` without `take` when the surrounding context proves the result set is bounded (e.g., the previous line is a `findUnique` on the parent).
- Style preferences about `select` vs `include`.

---

## Suggested-fix style

For N+1, suggest the batched form inline. For migration issues, suggest the safe variant (`CONCURRENTLY IF NOT EXISTS`, `ADD COLUMN … DEFAULT … NULL` then backfill then `SET NOT NULL`).
