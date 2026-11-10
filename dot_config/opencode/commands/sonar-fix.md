---
description: Fix what fails the SonarQube quality gate on a pull request, once CI has analysed it (optional PR number)
---
Fix what fails the SonarQube quality gate on a pull request of this repo. The server is CloudBees' SonarQube Server, and it only knows what CI analysed: this reads the PR's analysis, nothing analyses code locally.

Pull request, if given: $ARGUMENTS

1. Get the PR number: the one given above, else `gh pr view --json number,url` on the current branch. Stop if there's none.
2. From the repo root, read the verdict: `sonar quality-gate status --pull-request <n> --format json`. The CLI finds the project key by itself in some repos. When it can't, pass `-p` with the root `pom.xml`'s `groupId:artifactId` once `sonar api GET "/api/components/show?component=<key>"` confirms the server knows it, and ask me rather than guess if that doesn't settle it.
3. Stop on `OK` (the gate passes) or `NOT_COMPUTED` (CI hasn't analysed this PR yet), and say which.
4. Each failing condition comes with a breakdown, its issues or the files and lines behind it: that's the work list. `sonar api GET "/api/rules/show?key=<rule>"` explains a rule.
5. Fix the issues in the code, rule by rule, without changing behaviour. Leave an issue that is a false positive or needs a design decision, and say why.
6. For a coverage or duplication condition, write the missing tests or remove the duplication when the fix is clear. Otherwise, say which lines or blocks it is about.
7. Build, and run the tests your changes touch.
8. End with what you changed per condition and what's left. Don't commit or push: I review first.

Auth lives in the OS keychain: never pass, set or print a SonarQube token, and don't touch `SONARQUBE_CLI_*` variables. Use `sonar api` with GET only. Don't run bare `sonar analyze`, `sonar analyze agentic` or `sonar remediate`, which this server refuses, nor `sonar integrate`, `sonar config`, `sonar link`, `sonar auth login`, `sonar auth logout` or `sonar system reset`, which change local or global state.
