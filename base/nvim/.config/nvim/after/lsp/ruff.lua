return {
  -- pyrefly answers utf-16 whatever it is offered, so ruff must match it on python buffers
  capabilities = { general = { positionEncodings = { "utf-16" } } },
}
