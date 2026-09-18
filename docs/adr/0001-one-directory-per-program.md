# One directory per program, tiers computed

The repo is organised by program: `programs/<name>/` holds a program's `~`-shaped config tree
and a small declaration of its tier (Shell or Desktop), the platforms it exists on and how it
is installed. The tiers and the platform package lists are computed from those declarations,
never written as directories or lists of their own; what belongs to a platform rather than a
program lives under `platforms/<name>/`. We chose this over a tree organised by mechanism
(configs, Nix, pacman lists apart) and one organised by tier (`shell/`, `desktop/`) because
every day-to-day edit is to one program, so adding or removing one should be one directory,
and because tier and platform are attributes of a program rather than places to keep its files.
The cost is that a directory listing does not show the tiers; a task prints the computed view.
