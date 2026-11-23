---
name: repo-architecture-research
description: Research one or more repositories into evidence-backed architecture documentation — parallel read-only fact-sheet agents per repo plus Jira/Confluence context, then per-service notes and one "how it fits together" doc with mermaid diagrams. Use when asked to document a codebase or service group, write architecture docs, explain how services relate, onboard onto a multi-repo platform, or "research the repo first".
---

# Repo architecture research

Turn code into documentation a new engineer can trust. The output is not prose assembled from
impressions: every non-obvious claim carries a `file:line` (or ticket/page id), and anything you
could not verify is written as `UNKNOWN` instead of guessed.

## What it produces

1. **Fact sheets** — one per repository, plus one for the issue tracker and one for existing docs.
   Written by agents, stored outside the docs, never published.
2. **Per-service notes** — one note per repo/project.
3. **One architecture note** — service map, request paths, ownership, contracts, migration state.

Worked example of the full run: a 7-repo platform documented as one architecture note plus seven
service notes, with 19 mermaid blocks and a per-claim evidence table in every file. Look at an
existing set like `$MY_NOTE/projects/tdg/new-cda/` (note + `services/`, `_raw/` siblings in the
workspace `outputs/`) before writing a new one — matching an accepted house style beats inventing one.

## Step 0 — Preflight (do this yourself, not via agents)

- **Resolve the workspace.** If the working directory is a meta-repo of symlinks, note that each
  entry is a separate checkout; never assume sibling paths.
- **Pick the ref per repo, and write it down.** Prefer `development`, then the default branch, then
  the most advanced feature branch. Read other refs without touching the working tree:
  `git -C <repo> ls-tree -r --name-only origin/development`, `git show <ref>:<path>`,
  `git grep <pattern> <ref> --`. **Never** checkout, pull, stash, reset or write in these repos.
- **Expect ref surprises and record them.** Real cases: a repo with no `development` branch at all;
  a `main` branch holding only a README while the implementation lives on a feature branch. Say so
  in the note; a doc pinned to the wrong ref is worse than no doc.
- **Read the docs' destination conventions first** — note folder, template, frontmatter, index and
  log rules. If a `manage-notes` skill or a vault `AGENTS.md` exists, it wins over your habits.
- **Ask before writing into a human's notes tree** if the placement is ambiguous.

## Step 1 — Fan out fact sheets

One agent per repository, in parallel, in the background. Add a tracker agent and a
"what already exists" agent when those systems are reachable. Prompt skeletons and the required
output shape: `references/agent-prompts.md`, `references/fact-sheet.md`.

Non-negotiables in every fact-sheet prompt:

- read-only, no checkout, record ref + SHA;
- evidence table of `claim → file:line`;
- env/config **names only**, never secret values, never `.env` contents;
- `UNKNOWN` is a valid answer; absence claims must be scoped to the ref inspected;
- forbidden to infer from branch names, READMEs or "obviously it must work like…" — user-facing
  docs frequently contradict code, and code wins;
- "diagram-ready flows": numbered step lists so the writer can draw sequence diagrams without
  re-reading the repo.

Run them concurrently (5-9 is comfortable), keep each prompt self-contained, and have each write
its own file so nothing lands in your context until you choose to read it.

## Step 2 — Compose

Write the per-service notes from the fact sheets, then the architecture note last, when you can
see the whole picture.

- **Each service note:** role and boundaries (does / does not), where it sits, key flows as mermaid,
  API surface, data model, config, deployment, observability, risks, unknowns, evidence table.
- **The architecture note:** context diagram, old vs new request path side by side, route table
  (public gateway routes vs internal service routes are usually *different*), ownership matrix
  (which service writes each datastore), cross-service contracts, migration state, and a
  "consistency traps" section listing where the sources disagree.
- **Label provenance.** `planned` / `proposed` / `declared config` are not `deployed`. Tracker
  epics state intentions; deployment repos state desired configuration; neither proves a cluster.
- **Diagrams:** mermaid only, one idea per diagram, and name the concrete route or class in the
  label. Diagram hazards that silently break rendering: `references/mermaid-check.md`.

## Step 3 — Verify before claiming done

Run `scripts/check_notes.py <scan-root>` — it catches the failure classes that actually happened:
broken frontmatter, unbalanced fences, mermaid-hostile characters, and wikilink names that collide
with other notes or folders (a note named `architecture.md` collides with every other
`architecture.md` in the vault). It resolves path-qualified wikilinks from the vault root and exits
non-zero on errors; `--quiet` shows only errors.

For a hard check, parse every block with mermaid itself (`references/mermaid-check.md`). Do not
report "diagrams fine" when you only eyeballed them.

Also verify: every link target resolves; every note has its frontmatter; the index/log were
regenerated if the destination keeps them; and the numbers you quoted in prose (replica counts,
TTLs, limits) match the evidence table.

## Step 4 — Publish

- Write review copies where the task asked (often `outputs/<task>/`), and the canonical notes where
  the notes system says.
- Commit only the paths this task touched; never `git add -A`, never sweep unrelated dirt into the
  commit. Same for a vault with pre-existing uncommitted files.
- Put the raw fact sheets in a `_raw/` subfolder and reference them from each note, so a reader can
  audit a claim without rerunning the research.

## Definition of done

- [ ] Every repo has a note; the architecture note links all of them.
- [ ] Every note names its ref + commit, and any ref deviation is explained.
- [ ] Each non-obvious claim has a `file:line`; every "X does not…" claim is scoped to the ref.
- [ ] Risks include the ones that would hurt a production cutover (auth gaps, trust boundaries,
      destructive init containers, single-master stores, cache-vs-revocation, credential material
      committed to a repo).
- [ ] Sources that contradict each other are recorded, not silently reconciled.
- [ ] Mermaid blocks parse; links resolve; frontmatter valid.
- [ ] Reviewer can answer "what talks to what, who owns which data, and what is still migrating"
      from the architecture note alone.
