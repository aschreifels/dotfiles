---
name: voice-distill
description: Compress the accumulated voice corpus into the curated voice reference. Reads the raw signal pool at {kb.root}/people/{kb.owner}/voice/ (day-logs fed by wrap-session's voice-capture step, status needs-distillation) plus any writing samples the user provides, folds the new signal into {kb.root}/people/{kb.owner}/voice.md by DISTILLING (rewriting, not appending) under a strict size cap, shows the proposed changes for approval, then flips the folded day-logs to status distilled and runs the KB landing pass. Use whenever the user runs /voice-distill or says things like "distill my voice", "update my voice doc", "compress the voice corpus", "refresh my voice doc", or hands over writing samples to fold into their voice profile. Run periodically (end of day / end of week), not every session.
---

# voice-distill

Turns the growing, messy **corpus** of voice signal into the small, curated
**voice.md** that's loaded into core context every session (via the CLAUDE.md `@`
include). The corpus grows freely; voice.md must not. So distillation means
**rewriting to a sharper, still-small doc** — never appending.

Companion to `wrap-session`'s voice-capture phase (which *captures* into the corpus).
This skill is the *compression* pass the user runs on their own cadence.

## Files

Paths resolve from mindmeld.toml (`[kb] root` + `owner`); identity home =
`{kb.root}/people/{kb.owner}/`:

- `people/{owner}/voice.md` — the curated, always-loaded reference
  (`type: voice`, `status: distilled`). **Hard cap: ~150 lines of body** (frontmatter
  excluded). The output of this skill.
- `people/{owner}/voice/` — raw pending signal, **one log per day**
  (`<YYYY-MM-DD>.md`, `type: voice`, `status: needs-distillation`), fed by
  `wrap-session`. Input. `Voice.base`'s "Needs distillation" view is the queue.
- Folded day-logs are **never deleted or moved** (KB no-deletion rule) — a distill
  flips them to `status: distilled`, which drops them from the queue while keeping
  the long record in place. `scribe dream` owns any eventual compaction.

## Arguments

```
[sample-path-or-text ...]
```

- Optional. File paths to real artifacts Alex wrote (a PR body, a design doc, a
  Slack post) or pasted text. These are **the highest-signal input** — fold them
  in alongside the corpus. With no args, distill from the corpus alone.

## Flow

### 1. Gather

Read `voice.md` (current), every `status: needs-distillation` day-log in
`people/{owner}/voice/`, and any samples passed as args. If the queue is empty
**and** no samples were given, tell the user there's nothing to distill and stop.

### 2. Distill (the core move)

Produce a revised `voice.md` that integrates the new signal. This is editorial,
not mechanical:

- **Rewrite, don't append.** Merge each new observation into the right existing
  section; sharpen or replace weaker guidance rather than stacking bullets.
- **Corrections and real samples outrank inference.** A logged before→after edit,
  or a pattern from an actual artifact, beats anything guessed from chat. When
  they conflict, the real evidence wins and the inferred line is rewritten or cut.
- **Stay in the considered/artifact voice.** Capture vocabulary, framing, and
  structure — never bake in chat-looseness (typos, run-ons, interjections).
- **Fewer, sharper rules.** Prefer concrete lexicon and do/don't with examples
  over generic adjectives. If two rules say nearly the same thing, fuse them.
- **Enforce the cap.** If the result would exceed ~150 body lines, compress harder —
  drop the most generic / least-evidenced guidance first. Smaller-but-sharper
  always wins over comprehensive.
- **Frontmatter is contract** — keep the `type: voice` block intact; bump `updated:`.

### 3. Review gate (do not silently overwrite)

Show the user what will change before writing — a diff or a tight summary of
adds / rewrites / cuts, plus the projected line count vs. the cap. Wait for
approval; let them edit the proposal. (Alex reads diffs — respect that.)

### 4. Commit the result

On approval:
1. Write the revised `voice.md`.
2. Flip each folded day-log's frontmatter to `status: distilled` (bump `updated:`).
   Never delete or move them — the flip empties the queue; the record stays.
3. Run the KB landing pass (`scribe lint --changed` → `scribe sync --reindex` →
   `scribe commit`) — the commit is what carries the new voice to the other machines
   (the CLAUDE.md `@` include reads it live from the KB checkout).

### 5. Report

Tight summary: what moved in `voice.md` (sections touched, notable swaps), how
many day-logs folded + flipped, and final line count vs. cap.

## Rules

- **voice.md only ever shrinks toward signal.** Growth in *quality*, not size.
- **Never auto-write voice.md** without the review gate in step 3.
- **Don't invent traits** unsupported by the corpus/samples. Under-claiming beats
  putting words in his mouth.
- If the corpus has drifted into capturing chat-style noise, drop it during
  distillation rather than encoding it.
