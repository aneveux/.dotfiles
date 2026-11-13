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

Read a dependency's code from its sources jar, at the version the build resolves: one command, the
exact version, and the real source with its Javadoc. `javap -c` on a binary jar shows bytecode, not
the code, and decompiling is the last resort.

Resolve the version first: `mvn dependency:tree -Dincludes=<g>:<a>`. Then escalate in order,
stopping at the first step that works:

1. **Sources jar.** One artifact, inside or outside a project:
   `mvn dependency:get -Dartifact=<g>:<a>:<v>:jar:sources -Dtransitive=false`. Read it in place, at
   `~/.m2/repository/<group/path>/<a>/<v>/<a>-<v>-sources.jar`, with
   `unzip -p <jar> <package/path>/<Class>.java` or `zipgrep <pattern> <jar>`. Every dependency of the
   project: `mvn dependency:resolve-sources` (`dependency:sources` on a plugin older than 3.7.0). Go
   through Maven, not `curl` on a repository URL, so the mirrors and credentials apply. Never pass
   `-o`: offline mode is what makes the sources unavailable.
2. **A checkout**, for tests or history, or when no sources jar exists. Find the canonical repo in
   `<scm><connection>` or `<url>` of the artifact's own pom, at
   `~/.m2/repository/<group/path>/<artifact>/<version>/<artifact>-<version>.pom`. Do not guess the
   repo name from the artifactId: `ssh-slaves` lives at `jenkinsci/ssh-agents-plugin`. Use an
   existing checkout in `~/projects` (`ls -d ~/projects/*<name>*`, skipping the `worktrees-*` and
   `wt-*` worktrees), else `gh repo clone <org>/<repo> /tmp/<repo>`; a repo you will want again
   (Jenkins core, a CBCI monorepo) goes into `~/projects`.
3. **Decompile.** Only when neither exists: shaded or relocated artifacts, closed-source binaries.
   Say explicitly that you fell through to this step, and why.

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
`mvn jackknife:decompile` is step 3 only. See the generated `.jackknife/USAGE.md` for its full
command set.
