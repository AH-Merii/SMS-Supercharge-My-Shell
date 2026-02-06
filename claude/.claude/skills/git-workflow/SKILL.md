---
description: Git workflow conventions and commit patterns
autoActivateWhen: user asks to commit, create PR, review changes, or discusses git workflow
---

# Git Workflow Conventions

## Commit Format
Use conventional commits: `type(scope): description`
- feat: new feature
- fix: bug fix
- docs: documentation only
- refactor: neither fixes nor adds
- chore: maintenance tasks

## Before Starting
- Check CONTRIBUTING.md, Makefile, and Justfile if they exist for project-specific conventions
- Follow existing commit style visible in `git log`

## PR Workflow
1. Create feature branch from main
2. Make changes, test, lint
3. Commit with conventional format
4. Push: `git push -u origin <branch>`
5. Create PR: `gh pr create`

## Review Checklist (before committing)
- Run tests and lint
- Check `git diff --staged` for unintended changes
- Ensure no secrets/credentials in staged files
