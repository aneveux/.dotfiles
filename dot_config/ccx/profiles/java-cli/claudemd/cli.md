# Picocli CLI Conventions

- `@Command` per command; `@Option` (named) vs `@Parameters` (positional) — declarative, strongly typed
- `mixinStandardHelpOptions = true` — free `--help`/`--version`, never hand-roll them
- Picocli commands under Quarkus must be `@Dependent`, never `@ApplicationScoped` — a proxied scope breaks picocli's `@Spec`/field injection (ARC client proxy nulls the write)
- Multi-command apps: annotate the entry command `@TopCommand`; register `subcommands = {...}` on the parent
- Exit codes: return `int` from `Callable`/`Runnable`, or implement `IExitCodeGenerator` — don't `System.exit()`
- Capture output via `CommandLine.setOut(PrintWriter)` (there is no `setIn`) — makes commands testable
- Mutually exclusive / dependent options: model with `@ArgGroup`, not manual post-parse checks

Docs:
- https://picocli.info — user manual (subcommands §17, exit codes §9, arg groups §8)
- https://quarkus.io/guides/picocli — Quarkus command mode, `@TopCommand`, scope caveat

Defer to the `java-cli` skill for depth (annotation processor setup, native packaging, i18n, completion).
