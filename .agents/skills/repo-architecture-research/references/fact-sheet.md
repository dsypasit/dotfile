# Fact sheet template

One file per repository (or per topic: tracker, existing docs). Section headings matter more than
prose: the writer scans them, and a missing heading is an obvious gap.

```markdown
# <repo> — architecture fact sheet

## Meta
- Repository path; ref + full SHA; how the ref was chosen (and any ref that was empty/absent).
- Language, build tool, module/package manager, LOC estimate (say how it was counted).
- What was NOT inspected (working tree, submodules, other repos, live cluster).

## Purpose and boundaries
- What it does, who calls it, what it owns.
- What it explicitly does not own or do (this is where good docs earn their keep).

## Runtime topology
- Entrypoints (exact paths), processes/binaries, package layout, request/middleware order,
  background goroutines, workers, cron, concurrency model.

## API surface
- Table: method + exact path | auth | request fields | response shape | notable errors.
- Versioning, pagination, idempotency, content types.
- Note any difference between registered routes in code and documented/README routes.

## Data model
- Entities, keys, tables, JSON shapes, relationships, reserved/meta keys, TTL and retention.

## Data stores and consistency
- Which store, driver, pooling, migrations, caching, transaction boundaries, staleness.

## Integrations
- Table: peer | direction/protocol | contract | timeouts/retries | failure behaviour.

## Configuration
- Env/CLI/YAML **names** plus non-secret defaults. Never values of secrets. Note which names are
  derived rather than bound, and which documented names the code does not read.

## Deployment
- Dockerfile stages, exposed ports, non-root/root, health endpoints, manifests in-repo or absent,
  CI/CD steps that actually exist in this repo.

## Observability
- Log format and key fields, metrics names, tracing, health vs readiness semantics.

## Testing
- Unit/integration/e2e/load surfaces and what each proves; explicitly say tests were not run.

## Diagram-ready flows
- 4-8 numbered step lists: actor → component → store → upstream, including at least one failure or
  deny path.

## Risks and unknowns
- Numbered, each with the code that causes it. Mark anything unverified as UNKNOWN.
- Security: authn/authz gaps, trust boundaries, secret handling, sensitive logging.
- Operations: single points of failure, destructive startup, backup/restore, unbounded reads.

## Evidence
| Claim | File:line |
```

## Rules the agents keep

1. **Ref + SHA in Meta.** Every citation refers to that tree, not the working copy.
2. **Source beats documentation.** If the README and the code disagree, report the code and say the
   README is stale — with both paths.
3. **Absence claims are scoped.** "No Kafka integration found in `cmd/` and `internal/` at this ref"
   — not "there is no Kafka".
4. **Names only for secrets.** `JWT_SIGNING_KEY_PATH`, `redis-password-secret`, `app.apiToken` are
   fine; values, DSNs with passwords and `.env` bodies are not.
5. **UNKNOWN is required where evidence is missing** — deployment state, owners, SLAs, physical
   storage behind an HTTP endpoint, who writes a table the service only reads.
6. **Numbers carry their method.** "3,872 lines in 40 non-test files" beats "small codebase";
   "replicas 2, HPA disabled" beats "scaled".
7. **Config defaults vs deployed values** are different claims. Keep them separate.
