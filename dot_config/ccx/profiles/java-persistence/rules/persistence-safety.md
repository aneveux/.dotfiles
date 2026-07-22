---
description: "Persistence safety — N+1, transaction boundaries, entity leaking, lazy loading, unbounded fetches, parameterized queries"
globs: "**/*Entity.java,**/*Repository.java,**/*Service.java,**/entity/**/*.java,**/domain/**/*.java,**/repository/**/*.java,**/service/**/*.java"
---

# Persistence Safety

- No N+1: never trigger a query per row. Use JPQL `JOIN FETCH`, `@BatchSize`, or an entity graph to load associations in one round trip.
- No `@Transactional` on private, package-private, or `static` methods — CDI/proxy interception only fires on public methods, so the annotation is silently ignored.
- No entity leaking past the service layer — map to a DTO/record before returning from a REST resource. Never serialize a JPA entity to the API.
- No LAZY association access outside an active persistence context — resolve it inside the transaction to avoid `LazyInitializationException`.
- No unbounded fetches — every list query must paginate (`page()`/`range()` or `setMaxResults`). No blanket `listAll()`/`findAll()` on tables that can grow.
- Parameterized queries only — JPQL named or positional parameters. Never concatenate values into a query string.
