---
slug: connected-cli-and-operator-api
title: A Scrypath CLI, like gh for GitHub, that signs in to a running app's operator API so people and LLM agents can diagnose and fix search problems
status: planted
created: 2026-11-25
updated: 2026-11-25
trigger_when: v1.51 (the read-only agent diagnosis report) is complete or being scoped; or the operator UI is judged in good shape; or a remote or authenticated operator surface is proposed; or an adopter asks to run Scrypath operations against a deployed app without a shell on it
planted_during: v1.50 Adopter-ready, while the milestone was being opened
---

# Seed: a connected CLI and operator API

## Provenance

The maintainer, 2026-11-25, in the coding session that opened v1.50, verbatim:

> btw i just had an idea Record this in your opengsd second brain slash LLM wiki, high signal edits with Providence. I think this is an opengsd seed planted. We should have a CLI for this, kind of like GH CLI for GitHub and some of these other CLIs. This will make our library more accessible to LLM agents. So then, like, for example, if there's issues with. Like we have this admin slash operator UI. And I want to get that in a nice spot first. But then we should have, I guess, like an API that you can connect with. Using JWT or some kind of OAuth thing. So basically, then an LLM could authenticate, once you authenticate, Then LLM could automatically diagnose and fix issues. And all of the CLI stuff would follow our jobs to be done and user personas for this library.

("Providence" is dictation for "provenance".)

## What was asked

1. A Scrypath command-line client, in the spirit of `gh` and similar tools, so the library is easier for LLM agents to use.
2. An API on the running application that the client connects to, with authentication (JWT or some form of OAuth was suggested, not decided).
3. After authenticating, an agent can diagnose and fix issues on its own.
4. The CLI's commands follow the library's jobs to be done and user personas.
5. **Order:** the admin and operator UI gets into a good state first.

## How it relates to SEED-005

[SEED-005](SEED-005-ai-operable-scrypath.md) (2026-11-23) asks for agent diagnosis and guarded repair through a CLI, and its first slice is scheduled as v1.51: one read-only diagnosis report run **where the app runs** (a Mix task and a release-callable function). This seed is the step after: reaching a deployed app **from outside**, with its own sign-in. It changes the trust model, so it is kept separate and does not widen v1.51. The v1.51 report format is the natural body of the first API response, so design it with a remote consumer in mind.

## Open questions (none answered yet)

- **Authority:** who issues credentials, the host application or Scrypath? What stops a diagnose-only credential from writing? How are credentials revoked and expired?
- **Sign-in:** OAuth device authorization (the usual pattern for CLIs; verify against primary sources), host-issued short-lived tokens, or the host's existing operator authentication. A new auth system of Scrypath's own is the costliest choice.
- **Surface:** mounted by the host like ScrypathOps, off by default, and absent unless mounted. ScrypathOps is not on Hex today; does the API belong there or in the library?
- **"Fix automatically":** which actions may run unattended, which need a person's confirmation (production by default), and how each is verified rather than assumed from an accepted request.
- **Client:** Mix task, escript, standalone binary; which adds the least dependency and install burden. An MCP server stays a thin wrapper to decide later.
- **Safety:** error text and indexed content can carry instructions aimed at the agent; secrets and customer data must not leave through the API.
- **Command shape:** map each command to a persona and job in `reference/OPERATOR-UI-QUALITY.md` before naming it.

## Conflicts to settle before any work

- `PROJECT.md`'s scope guard excludes new auth models and new core APIs. This needs an explicit maintainer decision and an ADR.
- Prep note D ([v1.50 research](../research/v1.50-prep/D-agent-cli.md)) concluded that host credentials are the real boundary and recommended read-only first and no actions in the first slice. A remote write API goes beyond that and needs its own security review.

This is an idea to remember and weigh. It is not approved scope, and nothing here should be built or promised from this note alone.

## Related

- [SEED-005](SEED-005-ai-operable-scrypath.md), agent diagnosis through a local CLI.
- `PROJECT.md`, "Operator audience and automation direction" (2026-10-06).
- `reference/OPERATOR-UI-QUALITY.md`, roles and jobs.
