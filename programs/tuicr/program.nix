# nixpkgs is past 0.26, which is where the comment types the config names started
# reaching GitHub under the labels they are written with; the build from main is no longer needed
{
  tier = "shell";
  install = {
    linux.nixpkgs = "tuicr";
    darwin.nixpkgs = "tuicr";
    wsl.nixpkgs = "tuicr";
  };
}
