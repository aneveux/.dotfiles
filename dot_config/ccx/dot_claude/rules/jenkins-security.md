---
description: "Jenkins plugin security — CSRF, permissions, web-method safety, Jelly escaping"
globs: "**/*.{java,jelly}"
---

# Jenkins Plugin Security

- Annotate every form-submit / state-changing web method with `@POST` (or `RequirePOST`) to enforce the CSRF crumb
- Call `checkPermission(...)` in every `doXxx` web method and `doCheckXxx` validator — never assume the caller is authorized
- Gate administrative actions on `Jenkins.ADMINISTER`; use the narrowest permission that fits otherwise
- Store sensitive fields as `hudson.util.Secret`, never `String`; resolve runtime credentials via `CredentialsProvider`
- Escape all user-controlled output in Jelly (`<st:out>` / default escaping) — never emit raw HTML from untrusted input
- Never log `Secret` values, credentials, or tokens (and never call `Secret.getPlainText()` into a log)
- Validate form input in `doCheckXxx` methods returning `FormValidation`, not client-side only
