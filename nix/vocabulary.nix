# The tiers and the platforms of the glossary, named once. Everything that enumerates them
# reads them from here: the module's options, the configurations the flake exposes, and the
# linker's refusal of a declaration that names anything else. The order is the one the tiers
# task prints in.
{
  tiers = [ "shell" "desktop" ];
  platforms = [ "linux" "darwin" "wsl" ];
}
