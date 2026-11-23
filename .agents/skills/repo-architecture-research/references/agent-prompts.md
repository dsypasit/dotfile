# Agent prompt skeletons

Each agent runs independently and knows nothing you do not tell it. Hand it: the repo path, the
branch rule, what to extract, and where to write. Ask for a short reply (a summary is not the
deliverable; the file is).

## Common preamble (paste into every code agent)

```
You are gathering evidence for architecture documentation of <SYSTEM>. I need a precise,
evidence-backed fact sheet for ONE repo: **<REPO NAME>**.

Workspace: <WORKSPACE PATH> — top-level entries may be symlinks to real checkouts. Repo:
<ABSOLUTE REPO PATH>.

BRANCH RULE — read only, never modify:
- Prefer `origin/development` if it exists. Else the default branch (origin/HEAD), else the most
  advanced feature branch.
- Never checkout, pull, reset, stash, merge or write to the repo. Read another ref with
  `git -C <repo> ls-tree -r --name-only <ref>`, `git show <ref>:<path>`, `git grep <pat> <ref> --`.
- Record the exact ref and commit SHA you used, and say which ref you fell back to and why.

WHAT TO EXTRACT: <see references/fact-sheet.md sections>

DELIVERABLE: write Markdown to <OUT>/_raw/<name>.md using the headings in the template.
File paths for every non-obvious claim. No secrets — env var names only, never values.
Never invent; UNKNOWN is a valid answer.

Reply with <200 words: ref+sha, the 3 most important architectural facts, the biggest unknown.
Do not modify the repo. Write only that one file.
```

## Code agent — what to ask for

Purpose and boundaries · runtime topology and entrypoints · API surface (exact routes, auth,
errors) · data model · stores and consistency · integrations with timeouts/retries · config names
and defaults · deployment artefacts · observability · testing surfaces · diagram-ready flows ·
risks/unknowns · evidence table.

Add repo-specific bait when you know it exists: "read `docs/` and any swagger/openapi",
"postman/", "migrations", "helm values", "the `shared-docs` submodule is pinned but not to be read".

## Deployment agent (multi-repo)

Give it all repos in one prompt with aliases and a ref per alias, and demand:

- environment/cluster/namespace inventory;
- workload table: workload | namespace | image | replicas | resources | config source;
- networking: host + path → backend service, plugin/limits per route;
- data layer: managed vs in-cluster, availability, backup/PITR settings, storage classes;
- IaC: state backend, modules, key resources, node pools;
- CI/CD: what each workflow actually does (build vs notify vs deploy), and image tagging scheme;
- observability stack; secrets **names**;
- risks: committed secret material, destructive init containers, ZONAL/PITR-off databases,
  single-master caches, branch/tag drift between environments.

Say explicitly: "declared desired configuration, not verified running state".

## Tracker agent (Jira and friends)

Ask for: projects that hold the work; epics with key/summary/status/one-line scope; phases and
milestones with dates labelled as plans; decisions quoted with the ticket key; in-flight work;
risks/incidents; a ticket reference list with URLs; and **gaps the tracker does not answer**.

Instruct it to quote one sentence per decision and to report conflicts between tickets verbatim —
two tickets describing different request paths is a finding, not noise.

## Existing-docs agent (Confluence and friends)

Ask for: page inventory (space | title | id | URL | updated | project | summary); what the reference
folder actually contains (folders are not pages — resolve contents by CQL/descendants and say so);
business/domain facts; "statements of record" quoted with page id; what is already published so the
new docs link instead of repeat; contradictions and stale claims; gaps.

## Fan-out discipline

- Launch all agents in one message so they run concurrently; 5-9 agents is a good ceiling.
- One file per agent, under `<OUT>/_raw/`. Never let two agents write the same file.
- Do not also do the same reading yourself — that duplicates work and burns the context you need
  for writing.
- When a fact sheet lands, read it once and write the note from it. Do not re-open the repo to
  "double-check" unless the fact sheet is silent on something the note needs.
