# Java Core Conventions

Extends Java conventions.

## Constructor Injection
- Prefer constructor injection over field injection — no `@Autowired`/`@Inject` on fields
- Provide a no-arg constructor alongside `@Inject` constructor for framework compatibility
- Make injected fields `private final`

## Immutability
- Records for DTOs and value types
- `List.of()`, `Map.of()`, `Set.of()` for immutable collections
- Return defensive copies from getters on mutable fields

## Exception Handling
- Never swallow exceptions — log or rethrow, never empty catch blocks
- Unchecked exceptions for programming errors, checked for recoverable boundary conditions

## Null Safety
- `Optional<T>` as return type when absence is expected at API boundaries
- Never return `null` from public API — return empty `Optional` or empty collection
- `Objects.requireNonNull()` at constructor/method boundaries
