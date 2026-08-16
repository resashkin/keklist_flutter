# Code Style Rules

This document is the **source of truth** for code style in keklist. Any agent or
contributor writing code in this repository must follow these rules.

## Comments

- Do NOT write more than one line of comment per code block. One block gets at most one short line, and only when it explains "why", not "what".
- Do NOT restate the code in words. If a comment paraphrases what the code already shows, delete it.
- Multi-line comment blocks are forbidden (`///`, several `//` lines in a row, separator banners) above functions, classes, or inside method bodies.
- A comment is justified only for a non-obvious "why": a bug workaround, a platform requirement, a counter-intuitive ordering, a reference to a source.

## Self-documenting code

- Readability comes from the code, not from explanations: clear names for variables, functions, and types; small single-responsibility functions; early returns instead of nesting.
- If you feel the urge to write a heading comment over a chunk of a method, extract that chunk into a separate, well-named method instead.
- Replace magic numbers and strings with named constants rather than explaining them in a comment.
- A name must reveal intent: `daysSinceLastEntry`, not `d` with a comment.

## Move complex descriptions to documentation

- Long explanations (feature architecture, flows, edge cases, migration schemes) do not belong in code — move them to this `documentation/` folder as a separate markdown file.
- At most one line in the code may reference such a document, and only when truly needed.
- Document non-trivial features in `documentation/` following the structure in [CLAUDE.md](../CLAUDE.md#documentation).

## Bottom line

The goal is code that reads without comments. A comment is the exception, not a habit.
