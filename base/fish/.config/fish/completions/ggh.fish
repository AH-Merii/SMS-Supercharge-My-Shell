# Typer's generated completion, minus its --condition half: that ran the Python
# ggh a second time per Tab only to decide whether to fall back to file
# completion, and ggh takes no file or positional arguments.
complete --command ggh --no-files --arguments "(env _GGH_COMPLETE=complete_fish _TYPER_COMPLETE_FISH_ACTION=get-args _TYPER_COMPLETE_ARGS=(commandline -cp) ggh)"
