---
description: GitHub Actions CI/CD patterns and conventions
autoActivateWhen: user discusses CI, GitHub Actions, workflows, release automation, or .github/workflows files
---

# CI/CD Workflow Conventions

## Runtime Preferences
- Use `oven-sh/setup-bun@v2` instead of `actions/setup-node` for JS/TS
- Use `astral-sh/setup-uv` instead of `actions/setup-python` for Python
- Use `prefix-dev/setup-pixi` instead of conda/mamba actions for conda envs
- Use `bunx` instead of `npx` in all workflow steps
- Prefer `make`/`just` targets over inline commands when a Makefile or Justfile already exists

## Action Versions
- When modifying or creating workflows, check the latest version for each action used
- Ask the user if they want to update to the latest version or keep the current one
- The `check-actions-versions.sh` PostToolUse hook validates versions on save

## Workflow Structure
- Use minimal `permissions:` blocks
- Set `persist-credentials: false` on checkout for release workflows
- Use `GITHUB_TOKEN` not PATs when possible
