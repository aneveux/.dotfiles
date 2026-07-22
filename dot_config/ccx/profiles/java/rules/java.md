---
description: "Java code quality — naming, documentation, imports, readability"
---

# Java Code Quality

## Naming

- No abbreviations — `configuration` not `cfg`, `repository` not `repo`; only universally accepted shortforms are exempt (`id`, `url`, `dto`)
- Single-letter names only for loop indices (`i`, `j`) and type parameters (`T`, `K`, `V`) — never for variables or method parameters
- Boolean methods prefixed `is`, `has`, `can`, or `should`

## Documentation

- Every public class and public method has a Javadoc comment
- Javadoc describes the contract or intent, not the implementation — no paraphrasing the method name
- `@param` / `@return` / `@throws` only when the name alone is insufficient to convey meaning

## Imports

- Never use fully-qualified type names inline (`java.util.List<String>`) — always add an import
- No wildcard imports (`import java.util.*`) — import each type explicitly
- Limit static imports to test assertions (`assertThat`, `assertEquals`) and well-known DSL constants
