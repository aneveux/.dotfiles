---
description: Review a GitHub pull request — delegate to specialized agents, cite findings
argument-hint: "[pr-number|url]"
allowed-tools: Bash(gh *), Bash(jk *), Read, Write, Grep, Glob, Task
---

Review the pull request in `$ARGUMENTS` (number or URL). Follow the review heuristics rule.

## Steps

1. Fetch the PR: `gh pr view $ARGUMENTS --json title,body,state,isDraft,headRefName,files,url` and
   `gh pr diff $ARGUMENTS`. Skip closed/draft/automated PRs unless told otherwise.
2. Read the root `CLAUDE.md` and any in the touched directories — findings must respect project conventions.
3. Detect the stack. If a specialized reviewer agent fits (e.g. `java:java-reviewer` for Java/Quarkus),
   dispatch the diff to it and synthesize its findings. Otherwise review the diff directly.
4. If CI checks are red and the cause isn't clear from the diff, pull the failing Jenkins logs with `jk`
   (`jk use <instance>` then `jk logs <job> <build> --raw`) before drawing conclusions.
5. Rank findings: correctness/security (request changes) vs. nits (approve-with-nits). Drop false
   positives — pre-existing issues, linter-catchable style, unmodified lines, intentional changes.
6. Write all findings to `./review-pr-<number>.md` — do not report them ad hoc and do not post them.
   Each finding: `file:line`, severity, **rationale (why it matters)**, a concrete suggested fix, and
   its tier — **Confirmed** (factual basis shown) or **Suspected (unproven)** (clearly flagged, not
   presented as actionable). Follow the review rule's output & proof discipline.
7. Do **not** run any `gh` posting subcommand (`gh pr comment` / `gh pr review` / `gh api ... POST`).
   Post to GitHub only when I explicitly ask in the moment.
