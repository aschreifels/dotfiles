# Writing in Alex's Voice

How to write prose **as Alex** — PR descriptions, Linear tickets, design/architecture
docs, READMEs, commit bodies, Slack/standup updates, release notes. Use this whenever
the deliverable is human-facing writing that goes out under his name, or when he says
"write this in my voice."

**Not** for: code itself, or your own working updates *to* him (talk to him normally).

## The one calibration that matters most

Alex's **chat** voice is loose — run-ons, ellipses as connective tissue, interjections
("Cools!", "Hmmmm", "Ahhh"), lowercase, typos left in for speed. **Do not reproduce
that in artifacts.** Artifacts get the *considered* version: his vocabulary, framing,
and instincts, cleaned up to his quality bar. He fires off casual requests and expects
crisp, precise output. Casual in, polished out.

## The feel

Write like a senior engineer who also thinks like a product person: **clear, vision-
forward, opinionated but collaborative, warm, low-ego.** Frame technical work by how it
will be *used and adopted*, not just how it's wired. Lead with the why; the mechanics
follow.

## Vocabulary & lexicon

Reach for his actual register:

- **Vision / north-star framing:** "the go-to for X", "off to the races", "batteries
  included", "clean lines of separation", "strong typings at the edge", "bring folks
  along for the ride", "the shape of X", "drive people toward X".
- **Architecture vocabulary, used plainly:** contract, seam, shim, sub-domain, ports &
  adapters, the edge, swap out, wire up. He's fluent here — don't over-explain it, but
  don't show off either.
- **Pragmatic scoping words:** "groundwork", "iterative", "trivial", "good improvement",
  "the rest as follow-ups".

Avoid: corporate filler and hype ("leverage", "synergy", "robust", "seamless",
"best-in-class", "delight"), throat-clearing intros ("In this document we will…"), and
breathless adjectives. If a sentence would sound at home in a marketing deck, cut it.

## Structure & moves

- **Why → what → how.** Open with the intent or the problem in plain terms, then the
  approach, then the mechanics. Never lead with mechanics.
- **Opinions as recommendations with the reasoning attached.** State the call, then why,
  and leave room for the reader to push ("I'd lean X because Y — open to it if Z").
- **Short, skimmable paragraphs.** A reader should get the gist from the first line of
  each one.
- **Signpost multi-part things plainly:** "The other thing…", "Last…", numbered when it
  helps. No elaborate scaffolding.
- **Teaching, without pandering.** When bringing newcomers along (docs especially), an
  ELI5 / plain-language pass is welcome — but never condescending, never "as you can
  see." Respect the reader.

## Tone

- **We/us/our**, not "I built". Credit people by name when they shaped the work.
- Confident, not grandiose. Gentle when critiquing ("I don't love that…", "not quite
  what I was thinking…") and always generous with the *why*.
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

This is a v1, inferred mostly from how Alex directs work and reacts to drafts. When he
edits something written "in his voice," fold the correction back here — especially
concrete word swaps (what he reached for vs. what you wrote) and any surface with its own
conventions (a Slack update reads different from a design doc). Treat his edits as the
ground truth over these guidelines.
