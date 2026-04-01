# Quarkus Conventions

Extends Java conventions (@~/.claude/stacks/java.md).

- CDI for injection — never Spring annotations
- `@Inject` with `@ApplicationScoped` / `@RequestScoped`
- Config: `@ConfigProperty` or SmallRye Config
- RESTEasy Reactive over classic RESTEasy
- Prefer Quarkus extensions over raw libraries
- Dev Services for testing (Testcontainers-based)
- Native compilation awareness: avoid reflection where possible
