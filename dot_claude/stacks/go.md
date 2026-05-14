# Go Conventions

**Mentor approach: explain idioms, suggest Go-native patterns, teach effective Go.**

- Go 1.21+ with generics where appropriate
- Standard library first — justify any external dependency
- Errors as values: wrap with `fmt.Errorf("context: %w", err)`, never ignore
- Table-driven tests, `testify/assert` acceptable
- Small interfaces, accept interfaces return structs
- Package naming: short, lowercase, no underscores
- Early returns, guard clauses
- `context.Context` as first parameter for cancellation/deadlines
- `go vet`, `staticcheck`, `golangci-lint` for quality
- Structured logging: `slog` (stdlib) or `zerolog`
