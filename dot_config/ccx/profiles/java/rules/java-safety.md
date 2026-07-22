---
description: "Java safety — catch blocks, logging, type safety, SQL, injection"
---

# Java Safety

- No empty catch blocks — log or rethrow, never swallow
- No `System.out.println` for logging — use SLF4J
- No raw types — always parameterize generics
- No string concatenation in SQL — use `PreparedStatement` or JPA named parameters
- No field injection — use constructor injection
- Close all `Closeable` resources in try-with-resources, never finally blocks — including `Stream` from `Files.list()`, `Files.walk()`, and `Files.lines()`
- No `@SuppressWarnings("unchecked")` without an explaining comment
- No `Thread.sleep()` in production paths — use `ScheduledExecutorService` or reactive delays
