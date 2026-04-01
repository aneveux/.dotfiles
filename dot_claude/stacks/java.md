# Java Conventions

- Java 17+: records over POJOs, sealed classes, pattern matching
- Streams over loops, Optional over null checks
- Functional style: small pure functions, immutability by default
- Maven over Gradle
- Logging: SLF4J, never System.out/err
- Testing: JUnit 5 + AssertJ + Mockito
- Early returns, guard clauses
- Meaningful names, minimal comments

## Jackknife
- When you need to inspect, decompile, or find classes in jar dependencies,
  run `mvn jackknife:index` in the project. This generates `.jackknife/USAGE.md`
  with full instructions. Read that file — it has everything you need.
