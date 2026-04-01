# Jenkins Plugin Development

Extends Java conventions (@~/.claude/stacks/java.md).

Use the **graft** plugin for Jenkins work:
- `/agent jenkins-developer` — implementation
- `/agent jenkins-reviewer` — code review (P0/P1/P2 severity)
- `/agent jenkins-tester` — test generation

Skills: `jenkins-architecture`, `jenkins-pipeline`, `jenkins-testing`, `jenkins-ui`, `jenkins-reviews`

Key conventions:
- DataBoundConstructor / DataBoundSetter pattern
- Descriptor + Describable for configuration
- Jelly views with Design Library components
- JenkinsRule for tests, config roundtrip tests mandatory
- XSS prevention: Util.escape in Jelly
- @Symbol annotations for Pipeline step names
