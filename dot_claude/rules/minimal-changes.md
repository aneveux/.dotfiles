---
description: "Surgical edit discipline — minimum changes per request, with a structured reporting pattern for noticed-but-not-requested improvements"
---

# Minimal Changes

## Principle

Every changed line must trace directly to the request. If you can't point to a sentence in the request that caused a line to change, it's noise — revert it.

## Before Editing

Re-read the request. Identify the exact lines that must change. Resist the pull to clean, fix, or improve anything outside that scope.

## During Editing

Never introduce these unless explicitly requested:
- Adding or removing blank lines
- Reordering: imports, function definitions, object keys, enum values, case statements
- Fixing formatting or indentation in surrounding context
- Adding log statements, comments, or docstrings
- Applying linting or auto-formatting to untouched lines
- Renaming symbols outside the change
- Extracting functions, deduplicating code, adding abstractions

## After Editing — Required Self-Check

Before reporting the change as done:

1. Run `git diff` and read every changed line
2. For each changed line, verify it has a direct cause in the request
3. Revert any line that doesn't

Noise checklist — reject these silently added changes:
- Blank line added or removed without being asked
- Lines reordered without being asked
- Formatting changed on untouched lines
- Extra logic added "while you were in there"

## Reporting Noticed Issues

When you notice something that should be improved (dead code, missing log, unhandled error, inconsistent style, etc.):

1. **Do not apply it**
2. After delivering the requested change, surface it:
   > "I noticed X — should I address that too?"

One sentence per finding. No editorializing. Never bundle noticed issues into the current change.
