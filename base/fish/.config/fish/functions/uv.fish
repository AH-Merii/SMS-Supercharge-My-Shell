function uv --wraps uv --description "uv; 'uv init --docker' also fetches Docker files and GitHub's Python .gitignore"
    if test (count $argv) -eq 2; and test "$argv[1]" = init; and test "$argv[2]" = --docker
        set -l uv_example https://raw.githubusercontent.com/astral-sh/uv-docker-example/main
        set -l github_example https://raw.githubusercontent.com/github/gitignore/main
        command uv init
        and curl -fsSL $uv_example/Dockerfile -o Dockerfile
        and curl -fsSL $uv_example/.dockerignore -o .dockerignore
        and curl -fsSL $github_example/Python.gitignore -o .gitignore
    else
        command uv $argv
    end
end
