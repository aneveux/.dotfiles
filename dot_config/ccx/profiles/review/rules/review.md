# Review Heuristics

## What to check (in order)

1. Correctness first: error paths, edge cases, missing validation, resource leaks, off-by-one.
2. Security: injection, auth bypass, secret handling, unsafe deserialization.
3. Concurrency & performance: races, N+1 queries, unbounded loops/allocations.
4. Style last, and only when it affects clarity — never block on formatting CI already handles.

## Verdict policy

- Request changes only for correctness or security bugs.
- Approve with nits when all remaining issues are cosmetic.
- Include a concrete suggested fix with every non-trivial comment.

## Output & posting policy

- **Never post to GitHub on your own.** No `gh pr comment`, `gh pr review`, `gh api ... POST`, and no
  reply posting. Do the review, write everything to a local markdown file. Post only on an explicit,
  in-the-moment instruction from me — never as the default outcome of a review.
- **Output file**: write findings to `./review-pr-<number>.md` in the repo root. Feedback runs write
  to `./review-feedback-pr-<number>.md`.
- **Rationale required**: every remark states *why* it matters — the concrete failure mode or risk —
  not just what to change.
- **Proof discipline for suspicions**: when something looks fishy, re-check your reasoning and try to
  establish factual proof (trace the code path, cite the conflicting line, the spec, the test). Split
  the output into two tiers:
  - **Confirmed** — a factual basis is shown (`file:line`, cited behavior, repro reasoning).
  - **Suspected (unproven)** — you could not prove it. Say so explicitly, mark it clearly, and do not
    present it as an actionable defect.

## Delegation

- Prefer specialized reviewer agents when the repo's stack has one (e.g. `java:java-reviewer` for
  Java/Quarkus). Dispatch the diff to them and synthesize, rather than reviewing raw.
- Fall back to a direct read only when no specialized agent fits.

## CI context

- When a PR's checks are red and the failure isn't obvious from the diff, pull the failing Jenkins
  logs via `jk` before commenting.
