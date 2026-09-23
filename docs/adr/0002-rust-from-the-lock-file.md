# Rust comes from the lock file, not rustup

A machine's default Rust is `rustc` and `cargo` from nixpkgs, two programs because nixpkgs
ships them as two derivations. We chose this over `rustup`, which is what the repo used before
and what mise's Rust backend drives: rustup would put the manager in the lock file and leave
the toolchain it downloads in `~/.rustup`, outside it, which is the one thing a single lock
file exists to prevent. We also chose it over a `repo` package joining `rustc`, `cargo`,
`clippy` and `rustfmt` into one directory, and over letting mise own a global `rust`, which
the no-global-config rule closes outright. The cost is that `clippy` and `rustfmt` are not on
the machine, only the compiler and the package manager. That is deliberate and it costs
nothing in practice: a Rust project pins its own toolchain through mise, which bootstraps a
rustup of its own when none is installed and whose default profile carries both, so a global
pair would be solving a problem only where it is already solved. Revisit this if Rust starts
being written outside a pinned project often enough that reaching for a linter fails.
