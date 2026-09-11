# Data Model: Talk Page Skill Section

**Feature**: 002-talk-skill-section
**Date**: 2026-09-11

There is no database. Every entity is a file on disk or a hash the build attaches to a Jekyll document. Names below are the ones the plugin, templates, and tests use.

## Entities

### SkillFile (source)

One markdown file per talk, located by convention.

| Attribute | Source | Rules |
|---|---|---|
| `source_path` | `_skills/{stem}/SKILL.md` relative to site source | Directory name is the talk stem; file name is exactly `SKILL.md` |
| `stem` | `File.basename(File.dirname(source_path))` | Must equal a talk document's stem (`File.basename(doc.path, '.md')`) to be attached; otherwise the file is an **orphan** |
| `front_matter` | Leading `---` block, parsed with `SafeYAML.load` | Must be a YAML mapping |
| `name` | `front_matter['name']` | Required, non-empty string, matches `^[a-z0-9]+(-[a-z0-9]+)*$`, at most 64 characters |
| `description` | `front_matter['description']` | Required, non-empty string; leading/trailing whitespace trimmed |
| `body` | Everything after the closing `---` | Markdown; may be empty (a metadata-only skill is legal but pointless) |
| `raw_bytes` | The whole file | Served unchanged; the build never rewrites the source |

Other front-matter keys are preserved in the raw file and ignored by the page.

### Skill (attached to a talk document at build time)

`doc.data['skill']`, a plain Hash so Liquid can read it as `page.skill` / `talk.skill`. Absent (nil) when the talk has no valid skill file.

| Key | Type | Value |
|---|---|---|
| `name` | String | `SkillFile.name` |
| `description` | String | `SkillFile.description` (trimmed) |
| `html` | String | Body rendered by the site's markdown converter, passed through `HtmlSanitizer#sanitize_html`, headings demoted two levels |
| `url` | String | `/skills/{stem}/SKILL.md` (site-root-relative; templates apply `relative_url` / `absolute_url`) |
| `source_path` | String | `_skills/{stem}/SKILL.md` (for error messages and tests) |
| `install_dir` | String | `~/.claude/skills/{name}` |

### RawSkillFile (output)

A `Jekyll::StaticFile` subclass registered on `site.static_files` for each attached skill.

| Attribute | Value |
|---|---|
| `url` | `/skills/{stem}/SKILL.md` |
| `destination(dest)` | `{dest}/skills/{stem}/SKILL.md` |
| Content | Byte copy of `SkillFile.raw_bytes` |

Orphan skill files get no `RawSkillFile`: they are neither shown nor served.

### InstallInstruction (rendered, not stored)

Composed in the include from `Skill` and site config.

| Field | Value |
|---|---|
| `label` | `Claude Code (personal skills folder)` |
| `command` | `mkdir -p ~/.claude/skills/{name} && curl -fsSL {skill.url \| absolute_url} -o ~/.claude/skills/{name}/SKILL.md` |
| `generic` | Link to `{skill.url \| relative_url}` with the `download` attribute, plus one sentence for other assistants |

### Talk header / listing indicator

Derived: `page.skill` (talk page) or `talk.skill` (homepage loops) truthy ⇒ render `<span class="meta-item status-badge skill-available">Skill Available</span>` immediately after the video status badge. Falsy ⇒ render nothing.

## Relationships

```text
TalkDocument (_talks/{stem}.md)  1 ──── 0..1  SkillFile (_skills/{stem}/SKILL.md)
        │                                          │
        │ doc.data['skill']                        │ registered as
        ▼                                          ▼
      Skill (Hash)                           RawSkillFile (/skills/{stem}/SKILL.md)
        │
        │ rendered by _includes/skill_section.html
        ▼
   Skill section + header badge; homepage badge via talk.skill
```

Cardinality is enforced by the filesystem: one directory per stem, one `SKILL.md` per directory.

## States

| State | Condition | Build outcome | Page outcome |
|---|---|---|---|
| Absent | No `_skills/{stem}/SKILL.md` | Nothing happens | No section, no badge (byte-identical to today) |
| Present | File exists, validation passes, talk exists | `doc.data['skill']` set, raw file written | Section after media row, badge in header and listings |
| Invalid | File exists but any R3 validation fails | `Jekyll::Errors::FatalException` with `Skill _skills/{stem}/SKILL.md: {reason}`; no output written | Never published |
| Orphan | File exists, valid, no talk with that stem | Info log line, file skipped | Nothing anywhere |

## Validation rules (single source: `_plugins/skill_processor.rb`)

1. File starts with a front-matter block (`Jekyll::Document::YAML_FRONT_MATTER_REGEXP`).
2. Front matter parses to a Hash.
3. `name` present, String, non-empty after trim.
4. `name` matches `^[a-z0-9]+(-[a-z0-9]+)*$` and length ≤ 64.
5. `description` present, String, non-empty after trim.
6. Body renders through the site converter without raising.

Rules 1–5 fail the build. Rule 6 surfaces the converter's own exception unchanged.
