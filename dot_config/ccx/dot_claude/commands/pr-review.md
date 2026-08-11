---
description: Review a GitHub pull request — delegate to specialized agents, cite findings
argument-hint: "[pr-number|url]"
allowed-tools: Bash(gh *), Bash(jk *), Read, Write, Grep, Glob, Task
---

Review the pull request in `$ARGUMENTS` (number or URL).

## What to check, in order

1. Correctness first: error paths, edge cases, missing validation, resource leaks, off-by-one.
2. Security: injection, auth bypass, secret handling, unsafe deserialization.
3. Concurrency & performance: races, N+1 queries, unbounded loops/allocations.
4. Style last, and only when it affects clarity — never block on formatting CI already handles.

## Verdict policy

- Request changes only for correctness or security bugs.
- Approve with nits when all remaining issues are cosmetic.
- Include a concrete suggested fix with every non-trivial comment.

## Steps

1. Fetch the PR: `gh pr view $ARGUMENTS --json title,body,state,isDraft,headRefName,files,url` and
   `gh pr diff $ARGUMENTS`. Skip closed/draft/automated PRs unless told otherwise.
2. Read the root `CLAUDE.md` and any in the touched directories — findings must respect project conventions.
3. Detect the stack. Prefer a specialized reviewer agent when the repo's stack has one (e.g.
   `java:java-reviewer` for Java/Quarkus): dispatch the diff to it and synthesize its findings. Fall
   back to reviewing the diff directly only when no specialized agent fits.
4. If CI checks are red and the cause isn't clear from the diff, pull the failing Jenkins logs with `jk`
   (`JK_INSTANCE=<instance> jk logs <job-path> --raw`) before drawing conclusions.
5. Rank findings per the verdict policy above. Drop false positives — pre-existing issues,
   linter-catchable style, unmodified lines, intentional changes.
6. Write all findings to `./review-pr-<number>.md` — do not report them ad hoc and do not post them.
   Each finding: `file:line`, severity, **rationale (the concrete failure mode or risk, not just what
   to change)**, a concrete suggested fix, and its tier:
   - **Confirmed** — a factual basis is shown (`file:line`, cited behavior, repro reasoning).
   - **Suspected (unproven)** — you could not prove it. Say so explicitly, mark it clearly, and do not
     present it as an actionable defect.

   When something looks fishy, re-check your reasoning and try to establish factual proof (trace the
   code path, cite the conflicting line, the spec, the test) before assigning a tier.
7. **Never post to GitHub on your own.** No `gh pr comment`, `gh pr review`, `gh api ... POST`, and no
   reply posting. Post only on an explicit, in-the-moment instruction from me — never as the default
   outcome of a review.
