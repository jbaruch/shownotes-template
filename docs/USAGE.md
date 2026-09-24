# Usage Guide

How to create and manage conference talk pages.

## Creating Talk Pages

### Option 1: Migrate from Notist (Recommended)

The easiest way to add talks is to migrate them from Notist.

#### Prerequisites

- Google Drive API setup (see [Setup Guide](SETUP.md#google-drive-integration-optional))
- Notist talk URL

#### Migration Process

```bash
# One-command migration
ruby migrate_talk.rb https://noti.st/yourname/your-talk-id

# Example
ruby migrate_talk.rb https://noti.st/jbaruch/PjlHKD/robocoders-judgment-day-ai-ides-face-off
```

#### What the Migration Does

1. **Extracts content** from the Notist page:
   - Talk title, conference, date
   - Abstract/description  
   - Speaker information
   - Resource links

2. **Downloads and processes slides**:
   - Downloads PDF from Notist
   - Uploads to your Google Drive
   - Creates shareable embed link

3. **Downloads thumbnail**:
   - Extracts slide deck preview from Notist
   - Saves as local thumbnail file
   - Automatically displays in talk list

4. **Generates Jekyll markdown**:
   - Creates properly formatted talk file
   - Adds all extracted content
   - Uses clean, minimal frontmatter

5. **Validates everything**:
   - Runs focused tests on the new talk
   - Rebuilds Jekyll site
   - Verifies all resources work

#### Migration Output

```text
✅ Found talk: RoboCoders: Judgment Day – AI IDEs Face Off
✅ Downloaded PDF: 32.5MB
✅ Uploaded to Google Drive: 1PKbvxSb2XPNxDkPasli6IufGisPPTEOT
✅ Downloaded thumbnail: 2025-06-12-devoxx-poland-robocoders-judgment-thumbnail.png
✅ Generated: _talks/2025-06-12-devoxx-poland-robocoders-judgment.md
✅ Tests passed: 18 resources migrated successfully
✅ Jekyll site rebuilt
```

### Option 2: Manual Creation

For talks not on Notist or when you need full control.

#### 1. Create the Talk File

Create `_talks/YYYY-MM-DD-conference-talk-title.md`:

```markdown
---
layout: talk
---

# Your Talk Title

**Conference:** Conference Name YYYY  
**Date:** YYYY-MM-DD  
**Slides:** [View Slides](https://your-slides-url)  
**Video:** [Watch Video](https://your-video-url)  

A presentation at Conference Name YYYY in
                    Month YYYY in
                    City, Country by 
                    {{ site.speaker.display_name | default: site.speaker.name }}

## Abstract

Your talk description here. This should be a compelling summary
that explains what attendees will learn and why it matters.

## Resources

- [Main Resource](https://example.com)
- [Code Repository](https://github.com/yourname/repo)
- [Documentation](https://docs.example.com)
- [Related Tool](https://tool.example.com)
```

#### 2. Add Thumbnail (Optional)

Create or find a representative image:

- **Size**: 400x300 pixels recommended
- **Format**: PNG or JPG
- **Content**: First slide or representative image

Save as `assets/images/thumbnails/YYYY-MM-DD-conference-talk-title-thumbnail.png`

#### 3. Test and Build

```bash
# Test the new talk
TEST_SINGLE_TALK=your-talk-name bundle exec ruby test/migration/migration_test.rb

# Build site
bundle exec jekyll build

# Serve locally to verify
bundle exec jekyll serve
```

## Talk File Format

### Frontmatter

Minimal frontmatter is used:

```yaml
---
layout: talk
---
```

### Required Elements

```markdown
# Talk Title

**Conference:** Name and Year
**Date:** YYYY-MM-DD (ISO format)
**Slides:** [View Slides](URL)
**Video:** [Watch Video](URL) # Optional

A presentation at Conference Name in Month Year...

## Abstract

Description here...

## Resources

- [Resource](URL)
```

### Optional Elements

```markdown
# Additional sections you can add:

## Code Examples
## Demos  
## Follow-up
## References
```

## Resource Management

### Types of Resources

The platform automatically categorizes resources:

- **slides**: Slide deck URLs
- **video**: Video recordings
- **code**: GitHub repositories, code samples
- **link**: Documentation, articles, tools

### Resource URLs

#### Google Drive Slides (Preferred)

```markdown
**Slides:** [View Slides](https://drive.google.com/file/d/FILE_ID/view)
```

Benefits:
- Automatic embedding
- Thumbnail generation
- PDF integrity validation

#### Video Links

```markdown
**Video:** [Watch Video](https://www.youtube.com/watch?v=VIDEO_ID)
**Video:** [Watch Video](https://vimeo.com/VIDEO_ID)
```

#### Code Repositories

```markdown
- [GitHub Repository](https://github.com/username/repo)
- [Code Sample](https://gist.github.com/username/gist_id)
```

#### Documentation and Tools

```markdown
- [Official Documentation](https://docs.example.com)
- [Tool Website](https://tool.example.com)
- [Related Article](https://blog.example.com/article)
```

## Thumbnail Management

### Automatic Thumbnails (Notist Migration)

- Downloaded from Notist `og:image`
- Saved as `{talk-slug}-thumbnail.png`
- Automatically detected by Jekyll template

### Manual Thumbnails

1. **Create thumbnail image**:
   - Screenshot first slide of your presentation
   - Resize to ~400x300 pixels
   - Save as PNG or JPG

2. **Save with correct name**:
   ```bash
   # For talk: 2025-06-12-conference-my-talk.md
   # Save as: assets/images/thumbnails/2025-06-12-conference-my-talk-thumbnail.png
   ```

3. **Verify filename matches**:
   ```bash
   # Talk file basename should match thumbnail
   basename _talks/2025-06-12-conference-my-talk.md .md
   # Should match thumbnail prefix
   ```

### Fallback Behavior

- **Thumbnail exists**: Used automatically
- **Thumbnail missing**: Placeholder SVG used
- **Thumbnail fails to load**: Browser shows placeholder

## Skills

A talk can ship an [Agent Skill](https://agentskills.io): a `SKILL.md` file that packages the talk's know-how for coding agents (Claude Code, Codex, Cursor, Gemini CLI, and 30+ others support the format). Visitors install it from the talk page with one command.

### Location

```
_skills/{talk-stem}/SKILL.md
```

`{talk-stem}` is the talk's filename without `.md`, exactly as thumbnails use it:

```
_talks/2024-06-12-conference-talk-title.md
_skills/2024-06-12-conference-talk-title/SKILL.md
```

Drop the file, rebuild, done. No frontmatter or `_config.yml` changes. The `_skills/` directory is invisible to Jekyll's normal processing; the site's plugin picks the file up and serves it verbatim at `/skills/{talk-stem}/SKILL.md`.

### Format

```markdown
---
name: evaluate-ai-assistant-claims
description: Evaluate a vendor's productivity claim about an AI coding assistant. Use when someone quotes a percentage gain and asks whether to adopt the tool.
---

# Evaluate AI Coding Assistant Claims

Step-by-step instructions, examples, edge cases. Headings, lists, tables, and code blocks all render.
```

| Field | Rule |
|---|---|
| `name` | Required. Lowercase letters, digits, and single hyphens; 1–64 characters. Becomes the install folder and, in most agents, the slash command. |
| `description` | Required. 1–1024 characters. Say what the skill does *and* when to use it; agents pick skills by this text. |
| body | Optional markdown. Rendered on the page inside a collapsed "Show skill content" disclosure. `<script>` blocks are neutralised. Headings are shown two levels down so the page outline stays valid. |

Extra frontmatter fields (`license`, `metadata`, …) are allowed and preserved in the served file. A starter file is at [docs/templates/sample-skill.md](templates/sample-skill.md).

### What the page shows

When the file exists, the talk page renders a **Skill** section directly under the slides/video row, and a **Skill Available** badge appears next to the video status in the header and on the homepage cards. The section shows the name, the description, an install block, a download link, and the collapsed content. When the file is absent, nothing is rendered: no section, no badge, no placeholder.

### Installing (what visitors see)

The install block offers one command that works for every agent supporting Agent Skills:

```bash
npx skills add https://your-site/skills/{talk-stem}/SKILL.md -g
```

`-g` installs into the visitor's personal skills folders (all detected agents); without `-g` the CLI installs into the current project instead. Visitors without Node.js get a download link and the layout to place the file in: `{name}/SKILL.md` inside their agent's skills folder, for example `~/.claude/skills/{name}/SKILL.md` for Claude Code (personal) or `.claude/skills/{name}/SKILL.md` inside a repository (project).

### When the build fails

A broken skill file fails the build on purpose. The message always starts with the file path:

| Message | Fix |
|---|---|
| `Skill _skills/x/SKILL.md: missing front matter (file must start with ---)` | Add the `---` block at the very top |
| `…: front matter is not valid YAML: …` | Fix the YAML (quote values containing `:`) |
| `…: missing required field 'name'` / `'description'` | Add the field with a non-empty value |
| `…: 'name' must be lowercase letters, digits and hyphens (used as the install directory)` | Rename, e.g. `my-skill` |
| `…: 'description' must be at most 1024 characters` | Shorten the description |

A skill folder whose stem has no matching talk is ignored (logged at info level) and not served. A site with no `_skills/` directory at all builds normally.

### Local preview

```bash
bundle exec jekyll serve
open http://localhost:4000/talks/{talk-stem}/
```

Edits under `_skills/` trigger a rebuild like any other content. Copy-to-clipboard needs a secure context; `localhost` counts, so the Copy button works locally.

### Removing the demo skill

The template ships one demo skill for the DEMO talk of the same name. Remove it with the demo talks:

```bash
rm _talks/DEMO-*.md && rm -rf _skills/DEMO-*
```

## Embedded recordings and slides

The `Video` and `Slides` fields accept these embedded providers:

| Provider | Supported URLs | Notes |
|---|---|---|
| YouTube | `youtube.com/watch`, `youtube.com/live`, `youtube.com/shorts`, `youtube.com/embed`, and `youtu.be` | `t` and `start` timestamps are preserved, including values such as `1h2m3s`. |
| Vimeo | Public, channel, unlisted, and `player.vimeo.com/video` URLs | Tracking parameters are removed; an unlisted video's privacy hash is preserved. |
| Google | Slides presentations and Drive-hosted PDFs | Existing local-thumbnail and fallback behavior is unchanged. |
| Notist | `noti.st/{user}/{id}/...` | Share parameters and slide fragments are removed from the embed URL. |

Unknown, malformed, and host-lookalike URLs remain ordinary resource links instead of becoming iframes. Archive previews use the local talk thumbnail when one is available and never load a player iframe.

### Custom Notist domains

Custom Notist domains are opt-in so the template does not trust a speaker-specific hostname by default. Add hostnames without a scheme or path:

```yaml
resource_embeds:
  notist_custom_domains:
    - slides.example.com
```

Configured hosts are added to the page's `frame-src` policy and are expected to serve the presentation at `/{presentation-id}/embed` over HTTPS. Restart the Jekyll server after changing `_config.yml`.

## Guide for AI agents

The site publishes `/llms.txt`, generated from `llms.txt` during each Jekyll build. The shared page layout links to it through a `rel="describedby"` discovery link, including on the homepage and talk pages. It lists every talk newest first with its available Agent Skill, recording, and slides, so adding or updating talk metadata automatically updates the guide.

The guide tells agents to read a matching `SKILL.md` first for ordinary summaries and questions. When no suitable skill covers the question, agents should retrieve the linked YouTube transcript. Exact quotations and timestamps still require checking the recording or transcript. Livestream links retain their start times so agents can isolate the correct talk segment.

Edit the prose in `llms.txt` to change this behavior. The file provides navigation and source guidance; it does not fetch or host captions.

## Testing Your Talks

### Single Talk Testing

```bash
# Test specific talk during development
TEST_SINGLE_TALK=2025-06-12-conference-talk bundle exec ruby test/migration/migration_test.rb

# This tests:
# - File format validity
# - Resource accessibility  
# - Link validation
# - Thumbnail presence
# - Content completeness
```

### Full Site Testing

```bash
# Test all talks
bundle exec ruby test/run_tests.rb

# Test only migration-related functionality
bundle exec ruby test/run_tests.rb -c migration
```

## Best Practices

### File Naming

```bash
# Good
2025-06-12-devoxx-poland-robocoders-judgment.md
2024-04-15-spring-io-kotlin-coroutines.md

# Avoid spaces, special characters
# Use consistent date format (YYYY-MM-DD)
# Use hyphens for separation
```

### Resource Organization

```markdown
## Resources

# Group by category
### Documentation
- [Official Docs](https://example.com)
- [API Reference](https://api.example.com)

### Code and Examples  
- [GitHub Repository](https://github.com/user/repo)
- [Live Demo](https://demo.example.com)

### Related Reading
- [Blog Post](https://blog.example.com)
- [Research Paper](https://paper.example.com)
```

### Content Quality

- **Abstract**: 2-3 paragraphs explaining the value proposition
- **Resources**: Include only high-quality, relevant links
- **Links**: Test all URLs before publishing
- **Thumbnails**: Use clear, readable slide content

## Troubleshooting

### Migration Issues

#### PDF Download Fails
```bash
# Check Notist URL accessibility
curl -I https://noti.st/yourname/talk-id

# Verify PDF is available for download
# Some talks have PDF download disabled
```

#### Google Drive Upload Fails
```bash
# Verify API credentials
cat "Google API.json" | grep -o '"type".*"service_account"'

# Test API access
bundle exec ruby -c 'require "google-apis-drive_v3"'
```

#### Thumbnail Missing
```bash
# Check if thumbnail downloaded
ls assets/images/thumbnails/*your-talk*

# Manually add if needed
cp your-slide-image.png assets/images/thumbnails/your-talk-slug-thumbnail.png
```

### Manual Creation Issues

#### Talk Not Showing
```bash
# Verify filename format
ls _talks/YYYY-MM-DD-*

# Check Jekyll build
bundle exec jekyll build --verbose
```

#### Resources Not Working
```bash
# Test URLs individually
curl -I https://your-resource-url

# Check for typos in markdown
grep -n "http" _talks/your-talk.md
```

## Advanced Usage

### Custom Talk Templates

Create `_layouts/custom-talk.html` for specialized layouts.

### Bulk Operations

```bash
# Test multiple talks
for talk in _talks/*.md; do
  TEST_SINGLE_TALK=$(basename "$talk" .md) bundle exec ruby test/migration/migration_test.rb
done
```

### Content Validation

```bash
# Comprehensive validation
bundle exec ruby test/impl/integration/content_validation_test.rb
```

## Next Steps

- **Customize appearance**: See [Advanced Features](ADVANCED.md)
- **Deploy your site**: See [Advanced Features](ADVANCED.md#deployment)
- **Contribute to development**: See [Development Guide](DEVELOPMENT.md)
