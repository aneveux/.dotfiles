---
description: "Native-image safety — reflection registration, runtime resources, dynamic classloading"
globs: "src/main/java/**/*.java"
---

# Native-Image Safety

- Every type accessed reflectively at runtime needs registration, or it fails in the native binary (never on the JVM). Model records/DTOs deserialized by Jackson, types passed to `Class.forName`, and dynamic-proxy interfaces all need `@RegisterForReflection` (or a `reflect-config.json` entry for classes you don't own).
- No unguarded reflection on computed names — `Class.forName(variable)`, `ClassLoader.loadClass(...)`, and proxies over runtime-derived types are invisible to the closed-world analysis.
- Resources read at runtime (`getResourceAsStream`, config files, templates) must be listed in `quarkus.native.resources.includes` — nothing is bundled by default.
- No `--initialize-at-build-time` on a class holding runtime state (sockets, RNG seeds, native handles) — that state gets frozen into the image.
