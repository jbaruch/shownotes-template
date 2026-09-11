---
# ============================================================
# DEMO CONTENT - DELETE THIS DIRECTORY WHEN USING THE TEMPLATE
# Pairs with _talks/DEMO-ai-coding-assistants-2025.md
# Remove with: rm -rf _skills/DEMO-*
# ============================================================
name: evaluate-ai-assistant-claims
description: Evaluate a vendor's productivity claim about an AI coding assistant against the evidence checklist from the talk. Use when someone quotes a percentage gain and asks whether the team should adopt the tool.
---

# Evaluate AI Coding Assistant Claims

When a productivity claim about an AI coding assistant lands in front of you ("40% faster!"), do not argue with the number. Ask what it measured.

## Steps

1. Identify the task type behind the claim: boilerplate, tests, refactors, greenfield, or debugging. Reported gains cluster in the first two.
2. Ask for the baseline. "Faster than what?" A junior on an unfamiliar codebase and a senior on their own service are different denominators.
3. Check who reviewed the output and how long that took. Time saved typing is often time spent reading.
4. Look for the "vibe coding" tell: code merged without anyone being able to explain it. Treat that as a risk finding, not a productivity finding.
5. Recommend a two-week pilot on one real backlog slice, measured with the team's own before-and-after numbers.

## Output format

Reply with a short table:

| Claim | What it measured | Applies to us? | Pilot? |
|---|---|---|---|
| (quote it) | task type, baseline, reviewer | yes / partly / no | yes / no |

## Example

```text
Claim:     "55% faster with the assistant"
Measured:  time to first passing test on a toy HTTP server task
Applies:   partly (boilerplate-heavy service); not to our data pipelines
Pilot:     yes, 2 weeks, 3 volunteers, track PR cycle time
```
