function uv --wraps uv --description "uv; 'uv init --docker' (or --docker-multi for the multistage build) also fetches a Dockerfile and GitHub's Python .gitignore, copied to .dockerignore"
    if test (count $argv) -eq 2; and test "$argv[1]" = init; and contains -- "$argv[2]" --docker --docker-multi
        # Pinned upstream commits, so their changes can't break the edits below; bump by hand.
        set -l uv_repo_sha 694c26ad90e4cee1d42f4575dc850a4ae056828b
        set -l github_repo_sha 0e5d690153ca3da8a4a1aef2d053406f408f531c
        set -l uv_example https://raw.githubusercontent.com/astral-sh/uv-docker-example/$uv_repo_sha
        set -l github_example https://raw.githubusercontent.com/github/gitignore/$github_repo_sha
        set -l dockerfile Dockerfile
        test "$argv[2]" = --docker-multi; and set dockerfile multistage.Dockerfile
        command uv init
        and set -l python (string match -rg '^(\d+\.\d+)' <.python-version)
        # uv's examples pin Python 3.12 images; build on the project's major.minor instead.
        and curl -fsSL $uv_example/$dockerfile | string replace -r '^(FROM \S*python:?)3\.\d+' "\${1}$python" >Dockerfile
        and curl -fsSL $github_example/Python.gitignore -o .gitignore
        # .dockerignore anchors bare patterns at the context root, unlike .gitignore;
        # prefix them with **/ so nested .env and __pycache__ are excluded too.
        and string replace -r '^(!?)([^#!/][^/]*/?)$' '$1**/$2' <.gitignore >.dockerignore
    else
        command uv $argv
    end
end
