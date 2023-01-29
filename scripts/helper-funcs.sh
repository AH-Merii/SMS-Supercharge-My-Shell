#!/bin/sh

# checks if repo exists. if repo does not exist clones it else it pulls the most recent changes.
clone-repo() {
    repo=$1 
    repo_name=$(echo $repo | sed -rn 's/git@.+\/(.+)\.git/\1/p')
    # handle empty input for directory
    [ -z "$2" ] && directory="./" || directory=$2
    # check if repo is already cloned or not; if exists then pull
    if cd "$directory/$repo_name"; then git pull; else git clone --depth=1 $repo "$directory/$repo_name"; fi
}

# downloads the latest release of given repo that is compatible with linux
get-latest-release() {
    repo=$1

    curl -L "https://api.github.com/repos/$repo/releases/latest" | \
        jq -r ".assets[].browser_download_url" | \
        grep -Pi "(?=.*[_-]linux[_-])(?=.*[_-](amd64|x86_64).\b).*"
} 

# installs the latest release of repo
install-latest-release() {
    repo=$1
    program_name="$(awk -F/ '{print $2}' <<< $repo)"
    release_url=$(get-latest-release $repo)
    echo "Installing latest release of $program_name from: $release_url"
    pushd /tmp
    curl -Lo "$program_name.tar.gz" $release_url 
    tar -xf "$program_name.tar.gz"
    sudo install $program_name "$HOME/.local/bin"
    popd
}

# takes in command and input file and executes command on each line of the input file
loop-apply() {
    command=$1
    input_file=$2
    cat $input_file | while read line || [[ -n $line ]];
    do
      eval "$command $line"
    done
}
