---
name: Outside-adopter evidence
about: Report a failed or confusing Scrypath integration with enough detail to reproduce it
title: "[outside-adopter] "
labels: question, documentation
assignees: ""
---

## Adopter context

Briefly describe what you are trying to accomplish, such as running the repo-clone example path or adding Scrypath to an existing app.

## Evidence Block (required)

- Path:
- Runtime vs support matrix:
- Reporter class guess:
- Reporter finding guess:
- Scrypath ref or Hex version:
- First failing command step:
- Logs or artifacts:

Before posting logs or artifacts in this public issue, redact secrets, tokens, API keys, credentials, customer data, and sensitive private dumps.

## Environment matrix

- OS / architecture:
- Elixir version:
- OTP version:
- Meilisearch version:
- Database, if applicable:

## Scrypath ref or Hex version

State either the exact Hex package version or the exact git ref/commit.

## Chosen path

Are you running the repo-clone example path, or integrating the Hex package into another app?

## Sync mode

Which sync mode are you using?

- [ ] `:inline`
- [ ] `:manual`
- [ ] `:oban`

## Ordered commands

List the exact ordered commands you ran before the failure occurred.

1.
2.
3.

## Expected versus actual outcome

What did you expect to happen, and what actually happened?

## First failure or confusion point

At which step did the first failure or point of confusion occur?

## Supporting logs

Paste relevant shell output, error messages, or logs.

```text

```

## Maintainer review block

For maintainer use only.

- Classification (A-D):
- Finding bucket:
- Maintainer action:
