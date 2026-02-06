Initialize the development environment for this project:

1. Read the project's README, Makefile, Justfile, package.json, pyproject.toml, and pixi.toml (if they exist)
2. Identify the tech stack and required tools
3. Check which tools are installed: bun, uv, pixi, fish, git, gh, stow, fd, rg, btca
4. Report any missing dependencies
5. List available task runners and their targets:
   - Makefile targets (`make -qp`)
   - Justfile recipes (`just --list`)
   - pixi tasks (`pixi task list`)
   - pyproject.toml scripts/entrypoints
   - package.json scripts
6. Summarize the project structure and key entry points
