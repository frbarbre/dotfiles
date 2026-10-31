---
name: fba-stack-prs
description: Stack PRs in the work repo where every stacked element gets its own Linear issue and its own Orca worktree. Use whenever the user asks for stacked PRs, to split a branch into a stack, or to add an element to a stack. Replaces the repo's fb-stack-prs skill for this user; leave that one untouched.
---

# Stacked PRs with a Linear issue and an Orca worktree per element

This is the repo's `fb-stack-prs` skill plus one rule: **every element of a stack gets its own Linear issue and its own Orca worktree, set up the way `~/.linear/orca-open-issue.sh` sets up a worktree when the user opens an issue from Linear.** `fb-stack-prs` deliberately knows nothing about Linear or Orca; don't add this behaviour to it.

## Stacking (from fb-stack-prs)

Stack PRs on `main` with the `gh stack` CLI extension (`gh extension install github/gh-stack`). Never fake a stack with `gh pr create --base <other-branch>`.

- Open PRs with `gh stack submit --auto` (drafts). Not `--open`.
- Restructure the stack yourself, never with the interactive `gh stack modify`: reorder or drop branches with `git rebase --onto`, then re-declare the order with `gh stack unstack --local` and `gh stack init <bottom> ... <top>`.
- Let CI validate each branch; don't run the repo's local testbox on stack branches.
- Rebase, never merge `main` into a stack branch.
- If `gh stack rebase`/`sync` conflicts in files the stack never touched (often `pyproject.toml` or `uv.lock`), its cached heads are stale and it is replaying `main`. Abort, rebase by hand bottom to top with `git rebase --onto`, then `gh stack push`.
- Resolve conflicts across the whole stack in one pass, bottom to top. Stack branches may be checked out in other worktrees on disk: find them with `git worktree list` and edit, resolve and rebase there (`git -C <worktree> rebase --onto ...`). Push once at the end with `gh stack push`.

## One Linear issue per element

Read the repo's `LINEAR.md` first. Then, for each element, bottom to top:

1. Create a sub-issue of the originating issue (`parentId`), so the originating issue becomes the parent. Copy its project, milestone and priority. Set exactly one team label (Backend, Frontend, Full-stack, CI) and one type label, an estimate, `assignee: me`, state Backlog, and `blockedBy` the element below it.
2. Title the PR with the element's own identifier, e.g. `feat: … (E-6357)`, never the parent's. Linear links a PR through its branch name and title, so the parent's id in either one links the PR to the parent as well.
3. Never set In Review, Ready For Release or Done; the PR automation does. If a PR merged before its issue existed, attach the PR URL to the issue (`save_issue` `links`).

## One Orca worktree per element

Mirror `~/.linear/orca-open-issue.sh`:

```sh
orca worktree create \
  --repo path:<the repo's main checkout, from `git rev-parse --path-format=absolute --git-common-dir`, minus /.git> \
  --name <identifier, lowercased, e.g. e-6357> \
  --no-parent \
  --linear-issue <IDENTIFIER> \
  --base-branch <the branch of the element below, or main for the bottom one> \
  --json
```

- `--base-branch` is the one addition to the script, so the worktree starts on top of the element below it.
- Orca names the branch `frbarbre/<id>`. Rename it to the issue's `gitBranchName` (`git -C <worktree> branch -m <gitBranchName>`) before the first push. Linear links PRs by branch name.
- The script also copies the prompt to the clipboard and starts `claude --permission-mode plan` in the worktree. Skip both when setting up a whole stack at once, unless the user asks for agents.
- Link the PR to the worktree once it exists: `orca worktree set --worktree path:<worktree> --pr <number> --json`.
- Add an element to the stack (`gh stack add` / `gh stack init <bottom> ... <top>`) once its branch has commits. An empty branch can't become a PR.

## Gotchas

- **Never rename a PR's head branch on GitHub.** The branch rename API moves PRs that use the branch as their base, but it closes the PR whose head it is. Name the branch after its issue from the start. If an element's branch has the wrong name, open a new PR from the correctly named branch.
- When the bottom PR merges, GitHub deletes its branch and the stack rebases the next PR onto `main`, which gives its commits new SHAs. Fetch before reusing a stack branch locally.
- In zsh, `path` is tied to `PATH`. Never use it as a variable name in a loop (`wt` instead).
