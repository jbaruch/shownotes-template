# Quickstart: Talk Page Skill Section

**Feature**: 002-talk-skill-section
**Date**: 2026-09-11

## Prerequisites

- Ruby 3.4.5, Bundler, `bundle install` done (Jekyll 4.4.1 in `vendor/bundle`)
- On branch `002-talk-skill-section`
- Read [research.md](./research.md) R1–R6 and both files in [contracts/](./contracts/) first; the tests are written against them

## Implementation order

Tests first for each step (constitution: tests define expected behaviour), then the minimal code to pass them.

### Step 1: Plugin

Create `_plugins/skill_processor.rb` with `Jekyll::SkillRawFile < Jekyll::StaticFile` and `Jekyll::SkillProcessor < Jekyll::Generator` (`priority :high`). Behaviour per [data-model.md](./data-model.md): discover `_skills/*/SKILL.md`, validate (rules 1–5, `Jekyll::Errors::FatalException` with the source path in the message), render body via the site markdown converter → `HtmlSanitizer#sanitize_html` → heading demotion, attach `doc.data['skill']`, register the raw static file. Orphans: `Jekyll.logger.info`, skip.

Unit tests: `test/impl/unit/skill_processor_test.rb`.

### Step 2: Demo skill

Create `_skills/DEMO-ai-coding-assistants-2025/SKILL.md` (front matter with a `# DEMO CONTENT` comment, a short body with an `h1`, a list, and a fenced code block so rendering paths are exercised). No personal data.

### Step 3: Include and layout

Create `_includes/skill_section.html` per [contracts/rendered-html.md](./contracts/rendered-html.md). In `_layouts/talk.html`: add the badge after the video badge in `.talk-meta`; include the section right after the `talk-main-content` block (guarded by `{% if page.skill %}`). In `index.md`: add the badge after the video badge in both loops.

### Step 4: Styles and script

`assets/css/main.css`: `.talk-skill*` rules next to `.talk-resources`, `.status-badge.skill-available` next to the video badges, mobile rules inside the existing `@media (max-width: 768px)` block. `assets/js/skill-install.js`: IIFE, feature-detect clipboard, wire `[data-copy-target]` buttons, write status text.

### Step 5: Integration tests

`test/impl/integration/skill_section_test.rb`: real-site build (`'source' => Dir.pwd`, `'destination' => '_test_site'`) asserting the DOM contract, position, badges, raw-file byte identity, and absence on skill-less talks; temp-site build proving a malformed skill fails with the file path and an orphan is ignored.

### Step 6: Workflows and docs

Add `_skills/**` to the `paths:` lists in `.github/workflows/deploy.yml` and `.github/workflows/ci.yml`. Update `README.md` (Quick Start step, clean-up command), `docs/USAGE.md` (new "Skills" section), `docs/TESTING.md`, `docs/DEVELOPMENT.md` (pipeline), add `docs/templates/sample-skill.md`.

## Verify locally

```bash
# Plugin unit tests
bundle exec ruby -Itest test/impl/unit/skill_processor_test.rb

# Real-site integration tests
bundle exec ruby -Itest test/impl/integration/skill_section_test.rb

# Whole quick gate (what deploy runs)
bundle exec rake quick

# Build and eyeball
bundle exec jekyll build --config _config_test.yml
grep -c 'talk-skill' _site/talks/DEMO-ai-coding-assistants-2025/index.html   # > 0
grep -c 'talk-skill' _site/talks/DEMO-devops-revolution-2025/index.html      # 0
cmp _skills/DEMO-ai-coding-assistants-2025/SKILL.md _site/skills/DEMO-ai-coding-assistants-2025/SKILL.md && echo "raw file identical"

# Failure mode
mkdir -p _skills/DEMO-devops-revolution-2025 && printf -- '---\ndescription: no name\n---\n' > _skills/DEMO-devops-revolution-2025/SKILL.md
bundle exec jekyll build --config _config_test.yml   # expect: exit 1, message names the file
rm -rf _skills/DEMO-devops-revolution-2025

# Serve and check in a browser (light + dark, phone width, keyboard on the copy button and the disclosure)
bundle exec jekyll serve --config _config_test.yml
open http://localhost:4000/talks/DEMO-ai-coding-assistants-2025/
```

## Done when

- All new tests pass and the existing suite passes unchanged (`bundle exec rake test:unit test:integration`).
- `bundle exec jekyll build` completes with no warnings.
- Checklists in `checklists/` are fully ticked.
