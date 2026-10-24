function uv --wraps uv --description "uv; 'uv init --docker' (or --docker-multi for the multistage build) also fetches a Dockerfile and GitHub's Python .gitignore, copied to .dockerignore"
    if test (count $argv) -eq 2; and test "$argv[1]" = init; and contains -- "$argv[2]" --docker --docker-multi
        set -l uv_example https://raw.githubusercontent.com/astral-sh/uv-docker-example/main
        set -l github_example https://raw.githubusercontent.com/github/gitignore/main
        set -l dockerfile Dockerfile
        test "$argv[2]" = --docker-multi; and set dockerfile multistage.Dockerfile
        command uv init
        and curl -fsSL $uv_example/$dockerfile -o Dockerfile
        and curl -fsSL $github_example/Python.gitignore -o .gitignore
        # .dockerignore anchors bare patterns at the context root, unlike .gitignore;
        # prefix them with **/ so nested .env and __pycache__ are excluded too.
        and string replace -r '^(!?)([^#!/][^/]*/?)$' '$1**/$2' <.gitignore >.dockerignore
    else
        command uv $argv
    end
end
