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
(Corroborated across ~8 sessions: PRs and tickets written this way land without edits.)

## The feel

Write like a senior engineer who also thinks like a product person: **clear, vision-
forward, opinionated but collaborative, warm, low-ego.** Frame technical work two ways —
by how it will be *used and adopted*, and by what keeps it **legible for the team** (he
justifies structure and renames as *"makes more sense to others on the team"* / *"sets
up the pattern"*) — not just how it's wired. Lead with the why; the mechanics follow.

## Vocabulary & lexicon

Reach for his actual register:

- **Vision / north-star:** "the go-to for X", "off to the races", "batteries included",
  "clean lines of separation", "strong typings at the edge", "bring folks along for the
  ride", "set up the pattern (for the team)", "a nice point of parity", "the shape of X",
  "X replaces Y by design", "the new frontier".
- **Architecture, plainly:** contract, seam, shim, sub-domain, ports & adapters, the
  edge, swap out, wire up, "thread X everywhere", "building down / up from X", "painting
  ourselves into a corner", "the retiring substrate", "truly portable / REST-portable",
  "breadcrumbs" (a prior-work / in-code context trail). Fluent here — don't over-explain.
- **Pragmatic scoping:** "groundwork", "iterative", "trivial", "the rest as follow-ups",
  "saturate the required surface area", "logical commits", "a nice PR", "sub-base PR"
  (stacked), "level-setting is never bad", "the least we can ship safely", "do-now vs.
  the massive/last one" — and "boil the ocean" as the thing to *not* do.
- **Diagnosis & fixes:** "a break to the pattern", "Ruled out: …" (name what it wasn't),
  "load-bearing insight", and short triads — "stops the bleeding, cleans the mess, keeps
  it from regressing".

Avoid: corporate filler and hype ("leverage", "synergy", "robust", "seamless",
"best-in-class", "delight"), throat-clearing ("In this document we will…"), and
breathless adjectives. Prefer a hard number to an adjective ("~9.7k LOC, 83 call sites",
not "a huge surface"). If a sentence would sound at home in a marketing deck, cut it.

## Structure & moves

- **Why → what → how.** Open with the intent or problem in plain terms, then the
  approach, then the mechanics. Never lead with mechanics.
- **North-star first when it's a migration.** Open with the canonical distinction ("X
  replaces Y by design", "node-based, not leg-based"), then call out legacy leakage — he
  polices the model hard ("Itineraries shouldn't have ended up anywhere in here"). Keep
  the old dependency a swappable adapter detail, never in the seam/contract.
- **Behavior belongs with the domain.** Argue from where a thing *belongs* and what
  redundancy to cut, not just what to add. Enforcement/policy lives in business logic so
  it "travels to any caller (REST later)", not at the transport/edge; ports are verbs the
  domain calls, not a bag of injected actions ("is it not our domain to own what happens?").
- **Opinions as recommendations with the reasoning attached.** State the call, then why,
  leave room to push ("I'd lean X because Y — open to it if Z").
- **Diagnosis-first for fixes.** Lead with the precise observed symptom and what it
  *wasn't* ("Ruled out: …") before the fix — the corrected diagnosis, not the mechanics.
- **Sequencing over flat TODOs.** Frame follow-ups as who-owns-what-when ("Dan rewires
  his side first, then we support it"), and flag deferrals with an in-code breadcrumb
  ("parity for now — comment so we can revisit").
- **Flag the one pivot.** PR/ticket bodies carry a short "the pivot worth flagging" and an
  explicit Deferred / follow-ups callout; a mapping or gating table beats prose for a
  surface ("mutation → op", "PR × size × gated-by").
- **Short, skimmable paragraphs; signpost plainly** ("The other thing…", "Last…").
  **Teaching without pandering** — docs earn a plain-language pass, never "as you can see."

## Tone

- **We/us/our**, not "I built". Credit people by name when they shaped the work.
- Confident, not grandiose. Gentle when critiquing ("I don't love that…", "not quite what
  I was thinking…") and always generous with the *why*.
- Encouraging and forward-looking — there's usually a nod to where this is heading next.

## Rhythm note

His thinking moves in pivots and asides (in chat, that's the "…"). In artifacts, render
that with an em-dash or a short follow-on sentence — keep the momentum, drop the literal
ellipsis. Vary sentence length; a punchy short line after a longer one lands well.

## Quick before/after

- Flat: "This package provides a domain layer with a storage abstraction."
- Alex: "This package is the go-to for marketplace types and logic — storage lives behind
  a contract, so we can swap the backend later without touching the business logic above it."

- Flat: "Fixed the batch_id bug and added a guard."
- Alex: "Ruled out the marketplace package and the opportunity producer — the disjoint
  batch_id was a translation-layer drop. The fix stops the bleeding, cleans the mess, and
  keeps it from regressing."

## Evolving this

Now corroborated across ~8 sessions of real PRs, tickets, and completion comments that
landed without edits — the register here is well-established. The strongest live signals
are his **model-policing** (reasserting the canonical model, catching legacy leakage) and
his **where-behavior-belongs** instinct (domain owns policy; portability over transport-
coupling). Still no *literal prose edit* logged — when he rewrites something written "in
his voice," that's ground truth: fold the word-swap back here and let it outrank anything
inferred. Surfaces with their own conventions (a Slack update vs. a design doc) can diverge.
