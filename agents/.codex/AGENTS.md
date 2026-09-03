I'm Waishnav. I love building complex things as simply as possible and prefer opinionated solutions that reduce complexity.

## Coding preferences — general

- Keep things simple. Channel YAGNI energy unless told otherwise.
- Typesafety is useful, take advantage of it.
- Tests are good! Endless smoke tests, "regresssion tests" for feature deletetions, etc, are worse if that feature was under construction/experimentation not released and doesn't affect end users. Test should be focused, not slop and unwanted.
- Comments are a great way to clarify functionality and add notes about workarounds/tradeoffs that we have went with and how code is used. Don't comment every line, but feel free to describe (concisely)
- Keep comments up to date! When making changes, it's important to keep things in sync

## Philosophy

- Treat codebases as long-lived. Prefer maintainability and readability over short-term convenience.
- A shortcut can be reasonable for a quick personal project, but tell me when you make that tradeoff.
- No need to write unwanted and bloated tests for personal projects
- Prefer compositional patterns.
- Build reusable abstractions around clear responsibilities, but avoid indirection that does not reduce meaningful complexity.
- Use domain-driven design when it helps the code reflect the problem's language and boundaries. Do not force it where a simpler design is clearer.

## Working preferences

- Repository-specific instructions and conventions are authoritative when they conflict with these general preferences.
- Treat values supplied as examples as examples, not hard-coded product behavior.
- Make the smallest coherent change that solves the underlying problem. Include affected contracts, migrations, documentation, and verification when required for completeness.
- After two unsuccessful fixes for the same symptom, stop patching. Revert only your speculative changes, add instrumentation, compare against a known-good implementation, and reassess the diagnosis.
- Do not make me perform the first meaningful verification of an agent-applied fix when it can be reproduced locally.

## Dev servers and processes

- Do not start a long-running dev server unless I explicitly ask.
- Before starting a server, inspect relevant ports and processes. Do not kill or replace an existing process merely to claim its port.
- Capture the exact process started and its output. Report its URL, checkout, branch or commit, and relevant log location.
- Stop only a process you started or a port owner you have positively identified.
- Never use broad process matching such as `pkill -f`.
- Do not delete or reset application state to fix startup or migration errors without explicit permission.

## Pull requests

When explicitly asked to create or update a pull request, use the `raise-pr` skill. Use the `babysit-pr` skill to monitor reviews and CI or address review feedback.