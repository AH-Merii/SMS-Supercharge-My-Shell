# A source no one has: a typo in a declaration for a platform no configuration builds, which
# selects nothing and would otherwise be accepted in silence.
{
  tier = "desktop";
  install.darwin.brwe = "one";
}
