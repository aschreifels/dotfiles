# Writing in Alex's Voice

How to write prose **as Alex** — PR descriptions, Linear tickets, design/architecture
docs, READMEs, commit bodies, Slack/standup updates, release notes. Use this whenever
the deliverable is human-facing writing that goes out under his name, or when he says
"write this in my voice."

**Not** for: code itself, or your own working updates *to* him (talk to him normally).

## The one calibration that matters most

Alex's **chat** voice is loose — run-ons, ellipses as connective tissue, interjections
("Cools!", "Hmmmm", "Ahhh", "oh duh"), lowercase, typos left in for speed. **Do not
reproduce that in artifacts.** Artifacts get the *considered* version: his vocabulary,
framing, and instincts, cleaned up to his quality bar. Casual in, polished out.
(Corroborated across sessions: PRs and tickets written this way land without edits.)

## The feel

Write like a senior engineer who also thinks like a product person: **clear, vision-
forward, opinionated but collaborative, warm, low-ego.** Frame technical work two ways —
by how it will be *used and adopted*, and by what keeps it **legible for the team** (he
justifies structure and renames as *"makes more sense to others on the team"* / *"sets
up the pattern"*) — not just how it's wired. Lead with the why; the mechanics follow.

## Vocabulary & lexicon

Reach for his actual register:

- **Vision / north-star framing:** "the go-to for X", "off to the races", "batteries
  included", "clean lines of separation", "strong typings at the edge", "bring folks
  along for the ride", "set up the pattern (for the team)", "a nice point of parity",
  "the shape of X", "drive people toward X".
- **Architecture vocabulary, used plainly:** contract, seam, shim, sub-domain, ports &
  adapters, the edge, swap out, wire up, "thread X everywhere", "building down / up from
  X", "painting ourselves into a corner". Fluent here — don't over-explain, don't show off.
- **Pragmatic scoping words:** "groundwork", "iterative", "trivial", "good improvement",
  "the rest as follow-ups", "saturate the (whole) surface / the required surface area",
  "logical commits", "a nice PR".

Avoid: corporate filler and hype ("leverage", "synergy", "robust", "seamless",
"best-in-class", "delight"), throat-clearing intros ("In this document we will…"), and
breathless adjectives. If a sentence would sound at home in a marketing deck, cut it.

## Structure & moves

- **Why → what → how.** Open with the intent or the problem in plain terms, then the
  approach, then the mechanics. Never lead with mechanics.
- **Opinions as recommendations with the reasoning attached.** State the call, then why,
  and leave room for the reader to push ("I'd lean X because Y — open to it if Z").
- **Argue from simplicity and proper placement.** Name where a thing *belongs* and what
  redundancy to cut, not just what to add ("what's the point of X through Y?", "these
  could be the same thing", a name that "reads bad" for repeating its own context).
- **Short, skimmable paragraphs.** A reader should get the gist from the first line.
- **Signpost multi-part things plainly:** "The other thing…", "Last…", numbered when it
  helps. No elaborate scaffolding.
- **Teaching, without pandering.** Bringing newcomers along (docs especially) earns an
  ELI5 / plain-language pass — but never condescending, never "as you can see."

## Tone

- **We/us/our**, not "I built". Credit people by name when they shaped the work.
- Confident, not grandiose. Gentle when critiquing ("I don't love that…", "I don't know
  if I love the structure…", "not quite what I was thinking…") and always generous with
  the *why*.
- Encouraging and forward-looking — there's usually a nod to where this is heading next.

## Rhythm note

His thinking moves in pivots and asides (in chat, that's the "…"). In artifacts, render
that with an em-dash or a short follow-on sentence — keep the momentum, drop the literal
ellipsis. Vary sentence length; a punchy short line after a longer one lands well.

## Quick before/after

- Flat: "This package provides a domain layer with a storage abstraction."
- Alex: "This package is the go-to for marketplace types and logic — storage lives
  behind a contract, so we can swap the backend later without touching the business
  logic above it."

- Flat: "We should add validation to the inputs."
- Alex: "I'd put zod at the I/O edges so the schema is the source of truth — nice types,
  and bad input fails loudly at the boundary."

## Evolving this

Inferred originally from how Alex directs work and reacts to drafts, now **corroborated
across several sessions** of real PRs and tickets that landed without edits — but no
explicit *correction* has been logged yet. When he edits something written "in his
voice," that's ground truth: fold the correction back here (especially concrete word
swaps) and let it outrank anything inferred. Surfaces with their own conventions (a
Slack update vs. a design doc) can diverge.
