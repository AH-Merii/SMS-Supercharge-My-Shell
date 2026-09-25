# Not a checkout

A directory that exists and holds no `programs/`, which is the second thing the linker
refuses a checkout for: the first is a path with nothing at it at all.

It is here rather than borrowed from the collision fixture next door so that the two
refusals cannot break each other — a `programs/` directory added over there for a reason of
its own would quietly turn this case into a passing one. Nothing in here is read; only the
absence of `programs/` matters, so leave it as the one file.
