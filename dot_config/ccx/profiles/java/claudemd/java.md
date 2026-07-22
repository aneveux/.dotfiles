# Java Conventions

- Java 25+: records over POJOs, sealed classes, pattern matching
- Streams over loops, Optional over null checks
- Functional style: small pure functions, immutability by default
- Maven over Gradle — prefer `mvnd` for build/test operations
- Logging: SLF4J, never System.out/err
- Testing: JUnit 6 + AssertJ; use Mockito when mocking is actually needed — don't reach for it by default
- Early returns, guard clauses
- Meaningful names, minimal comments

## Jackknife
- When you need to inspect, decompile, or find classes in jar dependencies,
  run `mvn jackknife:index` in the project. This generates `.jackknife/USAGE.md`
  with full instructions. Read that file — it has everything you need.
