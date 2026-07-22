---
description: "Java security — injection, path traversal, secrets, crypto, TLS, auth"
globs: "**/*.java"
---

# Java Security Safety

- No string-concatenated SQL/JPQL/LDAP — use `PreparedStatement`, JPA named/positional parameters, or the Criteria API
- No `Runtime.exec` / `ProcessBuilder` with untrusted input — allowlist the command and arguments
- Validate path traversal: `normalize()` then confirm the resolved path stays under an allowed base directory before any file access
- No hardcoded secrets, API keys, passwords, or private keys in source — externalize to config/env or a secrets manager
- No disabled TLS verification — never install an all-trusting `TrustManager`, `HostnameVerifier`, or set `ssl.verify=false`
- No logging of credentials, tokens, session IDs, or PII
- No `MessageDigest` MD5 or SHA-1 for security purposes — use SHA-256+; use bcrypt/scrypt/Argon2/PBKDF2 for passwords
- `SecureRandom`, never `java.util.Random` or `Math.random()`, for tokens, salts, nonces, or keys
- Constant-time comparison (`MessageDigest.isEqual`) for secrets and MACs — never `String.equals`
