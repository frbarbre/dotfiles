# Global rules

## Git: never commit or push

Never run `git commit`, `git push`, or any equivalent unless explicitly told to. Only I commit and push code. When a task is finished, leave changes in the working tree and report what changed — I will review and commit myself.

## Never co-author

Never add `Co-Authored-By: Claude` (or any Claude/Anthropic identity) to commit messages or PR descriptions. Never add "Generated with Claude Code" footers. Commits and PRs must look like I wrote them — no trailers, no footers, no attribution to Claude.

This applies even if I explicitly ask for a commit later: still no co-author trailers.

## Comments

- **Default to no comments** — if code needs one to be understood, fix the code.
- **When you must: one line on _why_ (constraint, invariant, bug), never _what_.** No narration, no docstrings, no task references.

## File edits

Always change files with the Edit or Write tools. Never modify files through Bash (sed -i, perl -pi, heredocs, redirects, tee, or python/node scripts that write files).
