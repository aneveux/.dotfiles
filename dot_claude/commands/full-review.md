Do a comprehensive quality audit of the current project (or $ARGUMENTS if a specific file/directory is given).

## Review dimensions

1. **Readability**: naming, function size, cognitive complexity, dead code
2. **Architecture**: separation of concerns, dependency direction, abstraction levels
3. **Security**: OWASP top 10, secret handling, input validation, injection vectors
4. **Testing**: coverage gaps, missing edge cases, test quality
5. **Error handling**: swallowed errors, missing validation, unclear failure modes
6. **Patterns**: consistency with project conventions (check CLAUDE.md), FP patterns, early returns

## Process

1. Read CLAUDE.md and any project conventions first
2. Detect the language/stack from the project structure
3. Walk the source files — focus on logic, not boilerplate
4. For each finding: state the file, the issue, severity (P0/P1/P2), and a concrete fix
5. End with a summary: overall grade (A/B/C), top 3 things to fix first, and what's already done well

Keep findings actionable — no vague "consider improving X". Either it's a problem with a fix, or it's fine.
