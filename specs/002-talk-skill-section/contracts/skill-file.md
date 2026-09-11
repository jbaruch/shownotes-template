# Contract: Skill File

**Feature**: 002-talk-skill-section
**Consumers**: speakers dropping a file by hand, the speaker-toolkit publisher, the `skill_processor` plugin, tests.

## Location

```text
_skills/{talk-stem}/SKILL.md
```

`{talk-stem}` is the talk's page filename without `.md`, exactly as thumbnails use it (`_talks/geecon-2026-absolutely-right.md` → `_skills/geecon-2026-absolutely-right/SKILL.md`). Legacy date-prefixed stems keep their prefix.

## Format

```markdown
---
name: absolutely-right-review
description: Review a pull request the way the "Absolutely Right" talk recommends. Use when asked to review AI-generated code.
---

# Absolutely Right Review

Instructions for the agent, in markdown. Headings, lists, code blocks, links all render.
```

| Field | Required | Rule |
|---|---|---|
| `name` | yes | `^[a-z0-9]+(-[a-z0-9]+)*$`, ≤ 64 chars. Becomes the install directory and therefore the slash command in Claude Code. |
| `description` | yes | Non-empty. One or two sentences: what the skill does and when to use it. Shown verbatim on the page. |
| body | no | Markdown after the closing `---`. Rendered inside a collapsed disclosure. Raw HTML is passed through the site sanitizer; `<script>` blocks are neutralised. Headings are demoted two levels on the page (`#` renders as `h3`). |

Extra front-matter keys are allowed and preserved in the raw file.

## Build behaviour

| Situation | Result |
|---|---|
| Valid file, matching talk | Section + badges rendered; raw file served at `/skills/{talk-stem}/SKILL.md` |
| Missing file | Nothing rendered; talk page unchanged |
| Invalid front matter or missing/invalid `name`/`description` | Build fails: `Skill _skills/{talk-stem}/SKILL.md: {reason}` |
| Valid file, no talk with that stem | Ignored (info log), not served |

## Served address

```text
{site.url}{site.baseurl}/skills/{talk-stem}/SKILL.md
```

Byte-identical to the source file. `Content-Type` is whatever the host serves for `.md` (GitHub Pages: `text/markdown`); the install command uses `curl -o`, which does not care.
