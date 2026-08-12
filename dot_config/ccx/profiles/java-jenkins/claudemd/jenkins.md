# Jenkins Plugin Conventions

- Plugin POM inherits `org.jenkins-ci.plugins:plugin` parent; declare deps via BOM, not pinned versions
- Bind config with `@DataBoundConstructor` + `@DataBoundSetter`; describable/descriptor pattern, Jelly for views
- Contribute behavior through extension points annotated `@Extension` — never static singletons or service loaders
- Pipeline steps extend `Step` (async) or `SynchronousNonBlockingStep`; never block the CPS VM thread
- Sensitive fields use the `Secret` type and `CredentialsProvider` lookup — never store or accept plaintext credentials
- Permission-check every web method (`Jenkins.get().checkPermission(...)`) and gate admin actions on `Jenkins.ADMINISTER`
- Iterate locally with `mvn hpi:run`
- Reading a plugin's source: every Jenkins plugin is open source and every CBCI plugin is on GitHub,
  so decompiling one is always wrong. Get the repo from `<scm>` in the artifact's `~/.m2` pom
  (artifactId ≠ repo name), then follow the Dependency Investigation ladder. Jenkins core:
  `~/projects/jenkins`, tag `jenkins-<version>`. API signatures without a checkout:
  https://javadoc.jenkins.io/

Defer to the java-jenkins skill for depth (extension points, Stapler internals, Pipeline compatibility).

- Jenkins developer docs: https://www.jenkins.io/doc/developer/
- Plugin tutorial: https://www.jenkins.io/doc/developer/tutorial/
- Plugin security guide: https://www.jenkins.io/doc/developer/security/
- XSS prevention in Jelly: https://www.jenkins.io/doc/developer/security/xss-prevention/
