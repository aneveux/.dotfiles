# JPA / Hibernate / Panache Conventions

- Panache: pick one pattern per entity — active-record (`extends PanacheEntity`) for simple CRUD, repository (`PanacheRepository`) when logic needs mocking. Never mix on the same entity.
- `@ManyToOne`/`@OneToOne` are EAGER by default in JPA — make them `LAZY`. Fetch what you need with JPQL `JOIN FETCH` or an entity graph, never a lazy loop (N+1).
- Transaction boundaries live at the service layer (`@Transactional` on a public method). Managed entities are dirty-checked and flushed at commit — no explicit `save` needed for updates.
- Never access a LAZY association outside the persistence context — that is a `LazyInitializationException`. Fetch or map inside the transaction.
- `equals()`/`hashCode()` must not depend on a DB-generated `@Id` (null before persist). Use a business key or a client-assigned UUID.
- Never return an entity from a REST resource — map to a DTO/record inside the transaction.

Defer to the `java-persistence` skill for depth (mapping, fetch tuning, caching, migrations).

Docs:
- Panache — https://quarkus.io/guides/hibernate-orm-panache
- Hibernate ORM + Jakarta Persistence — https://quarkus.io/guides/hibernate-orm
- Hibernate 7.4 User Guide (fetching, transactions) — https://docs.hibernate.org/orm/current/userguide/html_single/Hibernate_User_Guide.html
