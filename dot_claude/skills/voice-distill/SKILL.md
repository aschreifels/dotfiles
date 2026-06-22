---
name: voice-distill
description: Compress the accumulated voice corpus into the curated VOICE.md reference. Reads the raw signal pool at ~/.config/ai/voice/corpus.md (fed by wrap-session's voice-capture step) plus any writing samples the user provides, folds the new signal into ~/.config/ai/VOICE.md by DISTILLING (rewriting, not appending) under a strict size cap, shows the proposed changes for approval, then archives the folded corpus entries and syncs VOICE.md to chezmoi. Use whenever the user runs /voice-distill or says things like "distill my voice", "update VOICE.md", "compress the voice corpus", "refresh my voice doc", or hands over writing samples to fold into their voice profile. Run periodically (end of day / end of week), not every session.
---

# voice-distill

Turns the growing, messy **corpus** of voice signal into the small, curated
**VOICE.md** that's loaded into core context every session. The corpus grows
freely; VOICE.md must not. So distillation means **rewriting to a sharper, still-
small doc** — never appending.

Companion to `wrap-session`'s Phase 4 (which *captures* into the corpus). This
skill is the *compression* pass the user runs on their own cadence.

## Files

- `~/.config/ai/VOICE.md` — the curated, always-loaded reference. **Hard cap:
  ~150 lines.** The output of this skill.
- `~/.config/ai/voice/corpus/` — raw pending signal, **one log per day**
  (`<YYYY-MM-DD>.md`), fed by `wrap-session`. Input. Not loaded into context;
  the active corpus only holds days not yet distilled.
- `~/.config/ai/voice/archive/` — folded day-logs are **moved** here after a
  distill (same filenames), for traceability. Prune it by hand whenever it gets
  large.

## Arguments

```
[sample-path-or-text ...]
```

- Optional. File paths to real artifacts Alex wrote (a PR body, a design doc, a
  Slack post) or pasted text. These are **the highest-signal input** — fold them
  in alongside the corpus. With no args, distill from the corpus alone.

## Flow

### 1. Gather

Read `VOICE.md` (current), every day-log in `voice/corpus/` (`*.md`), and any
samples passed as args. If `voice/corpus/` has no logs **and** no samples were
given, tell the user there's nothing to distill and stop.

### 2. Distill (the core move)

Produce a revised `VOICE.md` that integrates the new signal. This is editorial,
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
- **Enforce the cap.** If the result would exceed ~150 lines, compress harder —
  drop the most generic / least-evidenced guidance first. Smaller-but-sharper
  always wins over comprehensive.

### 3. Review gate (do not silently overwrite)

Show the user what will change before writing — a diff or a tight summary of
adds / rewrites / cuts, plus the projected line count vs. the cap. Wait for
approval; let them edit the proposal. (Alex reads diffs — respect that.)

### 4. Commit the result

On approval:
1. Write the revised `VOICE.md`.
2. **Move** the folded day-logs from `voice/corpus/` to `voice/archive/` (keep
   the same `<YYYY-MM-DD>.md` filenames; create `archive/` if missing) — leaving
   the active corpus empty for the next capture cycle. Don't delete them; the
   archive is the long record you prune by hand.
3. Sync the curated doc: `chezmoi add ~/.config/ai/VOICE.md`. Do **not** commit
   the corpus or archive (local working state).

### 5. Report

Tight summary: what moved in `VOICE.md` (sections touched, notable swaps), how
many corpus entries folded + archived, and final line count vs. cap.

## Rules

- **VOICE.md only ever shrinks toward signal.** Growth in *quality*, not size.
- **Never auto-write VOICE.md** without the review gate in step 3.
- **Don't invent traits** unsupported by the corpus/samples. Under-claiming beats
  putting words in his mouth.
- If the corpus has drifted into capturing chat-style noise, drop it during
  distillation rather than encoding it.
