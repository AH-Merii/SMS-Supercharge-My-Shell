function uv --wraps uv --description "uv; 'uv init --docker' also fetches Docker files and GitHub's Python .gitignore"
    if test (count $argv) -eq 2; and test "$argv[1]" = init; and test "$argv[2]" = --docker
        set -l uv_official_example https://raw.githubusercontent.com/astral-sh/uv-docker-example/main
        set -l github_official_gitignore https://raw.githubusercontent.com/github/gitignore/main
        command uv init
        and curl -fSL $uv_official_example/Dockerfile -o Dockerfile
        and curl -fSL $uv_official_example/.dockerignore -o .dockerignore
        and curl -fSL $github_official_gitignore/Python.gitignore -o .gitignore
    else
        command uv $argv
    end
end
