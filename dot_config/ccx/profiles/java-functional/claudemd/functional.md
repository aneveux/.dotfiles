# Functional Java Conventions

- Reach for the stdlib first — `java.util.function`, Streams, `Optional` cover most cases without a dependency
- Add Vavr only when you need richer FP: `Either`/`Try`/`Option`, pattern matching, persistent collections
- Railway-oriented errors: return `Either<Error, T>` or `Try<T>` at boundaries — don't throw for expected failures
- No side effects inside `map`/`filter`/`flatMap` — keep pipeline stages pure
- Total over partial functions — a function should return for every input (`Option`/`Either`), never throw on valid domain values
- Immutable data only: records, `List.of()`, Vavr persistent collections — never mutate shared state

Docs:
- https://docs.vavr.io — Vavr user guide (Option, Try, Either, collections)
- https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html — Java 25 Stream API

Defer to the `java-functional` skill for depth (Validation accumulation, Future, pattern matching, interop patterns).
