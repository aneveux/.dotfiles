# Java Conventions

- Java 25+: records over POJOs, sealed classes, pattern matching
- Streams over loops, Optional over null checks
- Functional style: small pure functions, immutability by default
- Maven over Gradle — prefer `mvnd` for build/test operations
- Logging: SLF4J, never System.out/err
- Testing: JUnit 6 + AssertJ; use Mockito when mocking is actually needed — don't reach for it by default
- Early returns, guard clauses
- Meaningful names, minimal comments

## Dependency Investigation

Real source is almost always obtainable. Decompiling is the last resort, never the first move.

Before reading code you don't own (a library, a plugin, a transitive dep), find the canonical repo:
read `<scm><connection>` or `<url>` from the artifact's own pom at
`~/.m2/repository/<group/path>/<artifact>/<version>/<artifact>-<version>.pom`. Do not guess the repo
name from the artifactId — `ssh-slaves` lives at `jenkinsci/ssh-agents-plugin`.

Then escalate in order, stopping at the first step that works:

1. **Existing local checkout.** `~/projects` is flat and holds ~220 repos; the dir name usually
   matches the repo name (`ls -d ~/projects/*<name>*`). Skip `worktrees-*` and `wt-*`, those are
   worktrees rather than primary checkouts.
2. **Clone it.** `gh repo clone <org>/<repo> /tmp/<repo>`. If it is a repo you will likely want
   again (Jenkins core, a CBCI monorepo), clone into `~/projects` so step 1 finds it next time.
3. **Source jar.** In-project: `mvn dependency:sources` for all deps. Single artifact:
   `mvn dependency:unpack -Dartifact=<g>:<a>:<v>:jar:sources -DoutputDirectory=target/src-<a>`.
   Never pass `-o` here — offline mode is what makes the sources unavailable.
4. **Decompile.** Only when no source exists anywhere: shaded or relocated artifacts, closed-source
   binaries. Say explicitly that you fell through to this step, and why.

**Pin the version, and never disturb a working tree.** Read the code at the revision the project
actually depends on, not at whatever HEAD happens to be. Find the tag with
`git -C <dir> tag --list '*<version>*'`, then read via `git -C <dir> show <tag>:<path>` or a
throwaway worktree (`git -C <dir> worktree add /tmp/<repo>-<version> <tag>`). Never `git checkout`
inside an existing `~/projects` checkout, that is a live working tree. Tag schemes vary: the literal
Maven version (`3894.vd0f0248b_a_fc4`), `vX.Y.Z`, or `<artifactId>-X.Y.Z`. A checkout at the wrong
revision produces confidently wrong answers, worse than not reading at all.

**Locating a class is a different question.** "Which jar holds `X`?" is cheap and is not decompiling:
`mvn dependency:list-classes -Dartifact=<g>:<a>:<v>`, or a jackknife class index
(`mvn jackknife:index`, then `Grep <ClassName> .jackknife/manifest/`). Use these freely at any step.
`mvn jackknife:decompile` is step 4 only. See the generated `.jackknife/USAGE.md` for its full
command set.
