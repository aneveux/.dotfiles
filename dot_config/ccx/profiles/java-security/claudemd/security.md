# Security Conventions

- Parameterized queries / prepared statements only — never build SQL, LDAP, or OS commands from concatenated input
- Validate and canonicalize path input before use (`Path.normalize()`, then verify it stays under an allowed base) — reject traversal
- Never hardcode secrets, keys, or tokens in source — inject via config/env or a secrets manager
- Bean Validation (`@Valid`, JSR-380 constraints) on every external input at the boundary; deny-by-default
- `@RolesAllowed` / OIDC / container-managed auth — never hand-roll authentication or session logic
- Constant-time comparison (`MessageDigest.isEqual`) for tokens, MACs, and secrets — never `equals`
- `SecureRandom` for anything security-sensitive; never log credentials, tokens, or PII

Defer to the java-security skill for depth (JWT/OIDC flows, TLS config, threat modeling).

- OWASP Cheat Sheet Series: https://cheatsheetseries.owasp.org/
- OWASP Top 10: https://owasp.org/Top10/
- Quarkus Security overview: https://quarkus.io/guides/security-overview
- Quarkus OIDC bearer-token auth: https://quarkus.io/guides/security-oidc-bearer-token-authentication
