Review PR #$ARGUMENTS comprehensively:

1. Fetch PR details: `gh pr view $ARGUMENTS`
2. Fetch PR diff: `gh pr diff $ARGUMENTS`
3. Fetch PR checks: `gh pr checks $ARGUMENTS`
4. Review the changes:
   - Are there any bugs or logic errors?
   - Are there security concerns?
   - Does it follow project conventions?
   - Are tests included for new functionality?
5. Summarize findings with specific file:line references
