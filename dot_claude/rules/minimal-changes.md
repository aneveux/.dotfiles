# Minimal Changes

Every changed line must trace to a sentence in the request. If it can't, it's noise — revert it.

Never introduce unless explicitly asked:
- Adding/removing blank lines, reordering imports/keys/definitions
- Reformatting or reindenting untouched lines
- Adding comments, docstrings, or log statements
- Renaming, extracting, deduplicating, or abstracting outside the change

Before reporting done: read `git diff`, confirm each line has a cause in the request, revert the rest.

Noticed an improvement (dead code, missing error handling, inconsistent style)? Do not apply it. Deliver the requested change, then surface it in one sentence: "I noticed X — address it too?" Never bundle it in.
