---
description: Systematic debugging approach for troubleshooting issues
autoActivateWhen: user reports a bug, error, failure, or asks to debug/investigate/diagnose an issue
---

# Systematic Debugging (Mitchell Hashimoto's pattern)

1. **Reproduce**: Confirm the issue is reproducible
2. **Isolate**: Find the minimal reproduction case
3. **Diagnose**: Read relevant code, trace execution path
4. **Fix**: Make the smallest possible change
5. **Verify**: Confirm fix without regressions

## Rules
- Read error messages and stack traces before acting
- Never guess at fixes -- understand root cause first
- Launch parallel Explore agents for different hypotheses (run_in_background: true)
- Check git log for recent changes that might have caused it
- For complex fixes, write spec.md with diagnosis before implementing

## Anti-patterns
- Don't add try/catch to hide errors
- Don't add defensive null checks without understanding why null occurs
- Don't retry flaky operations without understanding the failure mode
