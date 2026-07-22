# GraalVM Native Image + Release

- Reflection is invisible to the closed-world analysis — any reflectively-accessed type (Jackson records, dynamic proxies, JNI) needs reachability metadata. Prefer `@RegisterForReflection` on the type; fall back to `reflect-config.json` for third-party classes you can't annotate. A miss fails at *runtime*, not build — the JVM test suite won't catch it.
- Build-time vs runtime init — Quarkus initializes most beans at build time. Anything holding a live resource (RNG seeds, open sockets, loaded native libs) must be `--initialize-at-run-time`, or that state is baked into the image.
- Generate metadata, don't guess — run the tracing agent (`-agentlib:native-image-agent`) over a representative run to emit reflect/resource/proxy config, then commit it.
- Resources aren't bundled — list runtime-loaded files in `quarkus.native.resources.includes` (glob) or they won't exist in the image.
- Avoid dynamic classloading — `Class.forName` on computed names and runtime-derived proxies are unreachable to the analysis.
- Build native with `-Dnative` (`quarkus.native.enabled=true`); keep it reproducible — pin the Mandrel/GraalVM version and dependency versions.
- Release via jreleaser — a semver tag (`vX.Y.Z`) triggers release CI; jreleaser handles checksums, signing, the GitHub release, and the changelog.

Docs:
- https://www.graalvm.org/latest/reference-manual/native-image/metadata/
- https://quarkus.io/guides/building-native-image
- https://jreleaser.org/guide/latest/

Defer to the `java-graalvm` / `java-devops` skills for depth.
