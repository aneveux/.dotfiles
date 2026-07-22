# Quarkus Conventions

- CDI for injection — never Spring annotations
- `@Inject` with `@ApplicationScoped` / `@RequestScoped`
- REST: `quarkus-rest` (the reactive stack, formerly RESTEasy Reactive) — never classic RESTEasy
- Config: `@ConfigProperty` / SmallRye Config. Know build-time vs runtime config — build-time keys are baked into the native image and cannot change at launch.
- Prefer Quarkus extensions over raw libraries; Dev Services (Testcontainers) for local infra
- Test with `@QuarkusTest`; native awareness — avoid reflection, register it in `NativeConfig` when unavoidable

Defer to the `java-quarkus` skill for depth (extensions, reactive, native tuning).

Docs:
- REST (Quarkus REST) — https://quarkus.io/guides/rest
- Config reference (build-time vs runtime) — https://quarkus.io/guides/config-reference
- Native executable — https://quarkus.io/guides/building-native-image
- Testing — https://quarkus.io/guides/getting-started-testing
