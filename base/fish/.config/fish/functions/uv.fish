function uv --wraps uv --description "uv; 'uv init --docker' also fetches uv's example Dockerfile and .dockerignore"
    if test (count $argv) -eq 2; and test "$argv[1]" = init; and test "$argv[2]" = --docker
        set -l example https://raw.githubusercontent.com/astral-sh/uv-docker-example/main
        command uv init
        and curl -fSL $example/Dockerfile -o Dockerfile
        and curl -fSL $example/.dockerignore -o .dockerignore
    else
        command uv $argv
    end
end
