# Project Structure

## Directory Organization

```
shownotes/
├── _talks/                    # Talk content (markdown files) - Jekyll collection
├── _layouts/                  # Jekyll page templates - defines page structure
├── _includes/                 # Reusable template components - DRY principle
├── _plugins/                  # Custom Jekyll plugins - extends Jekyll functionality
├── lib/                       # Core Ruby libraries - business logic
│   ├── talk_renderer.rb      # Main rendering logic with embed support
│   └── simple_talk_renderer.rb # Lightweight renderer for testing
├── assets/                    # Static assets - served directly
│   ├── css/                  # Stylesheets - site styling
│   └── images/
│       └── thumbnails/       # Talk thumbnails - local storage for performance
├── test/                      # Test suite - organized by test type
│   ├── impl/                 # Implementation tests - tests for code
│   │   ├── unit/            # Unit tests - isolated component tests
│   │   ├── integration/     # Integration tests - component interaction tests
│   │   ├── e2e/             # End-to-end tests - full workflow tests
│   │   └── performance/     # Performance tests - speed and efficiency tests
│   ├── migration/           # Migration-specific tests - validates migration script
│   ├── external/            # External service tests - requires credentials
│   └── tools/               # Tool tests - tests for utility scripts
├── utils/                     # Utility scripts - helper tools
│   ├── migration/           # Migration utilities - migration helpers
│   └── google_drive/        # Google Drive helpers - Drive API utilities
├── docs/                      # Documentation - project documentation
├── _site/                     # Generated site (git-ignored) - production build output
├── _test_site/               # Test build output - test environment build
├── _perf_test_site/          # Performance test site - large dataset for perf testing
├── migrate_talk.rb           # Main migration script - single source of truth
├── _config.yml               # Jekyll configuration - site and speaker settings
└── Rakefile                  # Build and test tasks - task automation
```

## File Patterns

### Talk Files

**Location:** `_talks/`

**Purpose:** Store conference talk content as markdown files. Each file represents one talk and is processed by Jekyll into a static HTML page.

**Naming Convention:** `YYYY-MM-DD-conference-talk-title.md`

**Rationale:**
- Date prefix enables chronological sorting (newest first)
- Lowercase with hyphens improves URL readability
- Conference name provides context
- Talk title makes files self-documenting

**Format:** YAML frontmatter + Markdown content

**Frontmatter Schema:**

**Required fields:**
- `layout: talk` - Specifies which layout template to use

**Optional fields:** None currently used (content is in markdown body)

**Why minimal frontmatter:** Keeps files simple, reduces duplication, makes migration easier. All talk metadata is in the markdown content itself.

**Content Structure:**
```markdown
---
layout: talk
---

# Talk Title

**Conference:** Conference Name YYYY  
**Date:** YYYY-MM-DD  
**Slides:** [View Slides](URL)  
**Video:** [Watch Video](URL)  

A presentation at Conference Name in Month YYYY about [topic]...

## Abstract

Detailed description of the talk content and key takeaways...

## Resources

- [Resource Name](URL) - Description
- [Another Resource](URL) - Description
```

**Good Example:**
```markdown
---
layout: talk
---

# Coding Fast and Slow

**Conference:** DevConf 2025  
**Date:** 2025-10-01  
**Slides:** [View Slides](https://drive.google.com/...)  
**Video:** [Watch Video](https://youtube.com/...)  

A presentation at DevConf 2025 about developer productivity...

## Abstract

This talk explores the dual-process theory applied to software development...

## Resources

- [Thinking, Fast and Slow](https://example.com/book) - Original book
- [Study on Developer Productivity](https://example.com/study) - Research paper
```

**Bad Example:**
```markdown
---
layout: talk
title: Coding Fast and Slow  # Don't put content in frontmatter
conference: DevConf 2025     # Keep frontmatter minimal
---

Coding Fast and Slow         # Missing heading level

Conference: DevConf 2025     # Missing bold formatting
Date: 2025-10-01

Slides: https://...          # Missing markdown link format
```

**Validation Rules:**
- Must have `layout: talk` in frontmatter
- Must have H1 heading for title
- Should have conference, date, slides, video (when available)
- Should have abstract section
- Should have resources section (when applicable)

### Thumbnail Files

**Location:** `assets/images/thumbnails/`

**Purpose:** Provide visual preview images for talks in list views and social media sharing.

**Naming Convention:** `{talk-slug}-thumbnail.png` or `{talk-slug}-thumbnail.jpg`

**Matching Rule:** Thumbnail filename must match talk filename (without date prefix and .md extension)

**Example:**
- Talk file: `_talks/2025-10-01-devconf-coding-fast.md`
- Thumbnail: `assets/images/thumbnails/devconf-coding-fast-thumbnail.png`

**Format Requirements:**
- PNG or JPG format
- Recommended size: ~400x300px (4:3 aspect ratio)
- File size: < 200KB for performance
- RGB color space (not CMYK)

**Fallback Behavior:**
- If thumbnail missing: `placeholder-thumbnail.svg` is used
- Fallback is automatic, no configuration needed
- Fallback provides consistent visual appearance

**Generation Process:**
- Migration script downloads thumbnails automatically from Notist
- Manual creation: Create or download thumbnail, save with correct name
- Optional: Use screenshot tools or design tools to create custom thumbnails

**Good Example:**
- File: `devconf-coding-fast-thumbnail.png`
- Size: 400x300px
- Format: PNG with transparency
- File size: 85KB

**Bad Example:**
- File: `thumbnail.png` - Doesn't match talk slug
- Size: 2000x1500px - Too large, slow loading
- Format: CMYK JPEG - Wrong color space
- File size: 2.5MB - Way too large

### Layout Files

**Location:** `_layouts/`

**Purpose:** Define page structure and HTML templates for different page types.

**Main Layout:** `talk.html` - Template for individual talk pages

**Template Variables Available:**
- `site.speaker.*` - Speaker profile from `_config.yml`
- `page.content` - Rendered markdown content
- `page.url` - Page URL
- `page.title` - Extracted from H1 heading
- `site.talks` - Collection of all talks

**Customization Points:**
- Header structure
- Footer content
- Metadata tags
- Social sharing buttons
- Navigation elements

**Liquid Templating:**
```liquid
{% for talk in site.talks %}
  <h2>{{ talk.title }}</h2>
  <div>{{ talk.excerpt }}</div>
{% endfor %}
```

**Best Practices:**
- Use includes for reusable components
- Escape user content: `{{ content | escape }}`
- Use semantic HTML5 elements
- Include accessibility attributes
- Test with multiple talks

### Library Files

**Location:** `lib/`

**Purpose:** Contain core Ruby business logic for rendering and processing.

**talk_renderer.rb:**
- **Purpose:** Full-featured renderer with Google Slides/YouTube embed support, XSS protection, resource management
- **When to use:** Production builds, migration script, full functionality needed
- **Features:** Embed detection, HTML escaping, resource parsing, thumbnail handling
- **Dependencies:** nokogiri, Google APIs
- **Security:** XSS protection via `CGI.escapeHTML()`

**simple_talk_renderer.rb:**
- **Purpose:** Lightweight version for testing without heavy dependencies
- **When to use:** Unit tests, fast test execution, no external services needed
- **Features:** Basic rendering, minimal dependencies
- **Dependencies:** Standard library only
- **Trade-off:** Speed vs features

**Usage Pattern:**
```ruby
# Production
require_relative 'lib/talk_renderer'
renderer = TalkRenderer.new
html = renderer.render(talk_content)

# Testing
require_relative 'lib/simple_talk_renderer'
renderer = SimpleTalkRenderer.new
html = renderer.render(talk_content)
```

## Content Conventions

### Talk File Structure

**Complete Annotated Example:**

```markdown
---
layout: talk                    # Required: Specifies layout template
---

# Coding Fast and Slow          # Required: H1 heading, becomes page title

**Conference:** DevConf 2025    # Recommended: Conference name and year
**Date:** 2025-10-01            # Recommended: ISO date format (YYYY-MM-DD)
**Slides:** [View Slides](https://drive.google.com/...) # Optional: Link to slides
**Video:** [Watch Video](https://youtube.com/...)       # Optional: Link to video

A presentation at DevConf 2025 in Denver about developer productivity and the
dual-process theory applied to software development.  # Recommended: Brief intro

## Abstract                      # Recommended: Detailed description

This talk explores how Daniel Kahneman's dual-process theory (System 1 and
System 2 thinking) applies to software development. We'll examine when to use
fast, intuitive coding versus slow, deliberate problem-solving, and how to
recognize which mode is appropriate for different tasks.

Key takeaways:
- Understanding cognitive modes in programming
- Recognizing when to switch between fast and slow thinking
- Practical techniques for improving code quality
- Balancing speed and correctness in development

## Resources                     # Optional: Related links and materials

- [Thinking, Fast and Slow](https://example.com/book) - Daniel Kahneman's original book
- [Study on Developer Productivity](https://example.com/study) - Research paper
- [Code Examples](https://github.com/...) - GitHub repository with examples
- [Slides (PDF)](https://example.com/slides.pdf) - Downloadable slide deck
```

### Frontmatter Schema

**Required Fields:**

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| layout | string | Layout template name | `talk` |

**Optional Fields:** None currently defined

**Validation:**
- YAML must be valid (use `YAML.safe_load` to test)
- `layout` must be `talk` (only supported layout)
- No other fields are processed (content is in markdown)

**Why So Minimal:**
- Reduces duplication between frontmatter and content
- Makes files easier to read and edit
- Simplifies migration from other platforms
- Keeps all visible content in markdown body

### Markdown Conventions

**Heading Hierarchy:**
- H1 (`#`): Talk title only (one per file)
- H2 (`##`): Major sections (Abstract, Resources, etc.)
- H3 (`###`): Subsections (rarely needed)
- Don't skip levels (H1 → H3 is bad)

**Link Formats:**
- External links: `[Link Text](https://example.com)`
- Always use full URLs including `https://`
- Use descriptive link text, not "click here"
- Add context after link: `[Resource](URL) - Description`

**Resource Lists:**
- Use unordered lists (`-` or `*`)
- One resource per line
- Format: `- [Name](URL) - Description`
- Group related resources with subheadings if many

**Code Blocks:**
```markdown
```language
code here
```
```

- Specify language for syntax highlighting
- Supported: ruby, javascript, python, bash, yaml, etc.
- Use for commands, code examples, configuration

**Emphasis:**
- Bold: `**text**` for labels (Conference:, Date:)
- Italic: `*text*` for emphasis (rarely needed)
- Don't overuse formatting

**Line Breaks:**
- Two spaces at end of line for hard break
- Blank line for paragraph break
- Use blank lines to separate sections

## Testing Structure

### Test Organization

**test/impl/unit/**
- **Purpose:** Test individual components in isolation
- **Scope:** Single classes, methods, functions
- **Dependencies:** Minimal, use mocks/stubs
- **Speed:** Fast (milliseconds per test)
- **Examples:** Renderer tests, parser tests, utility tests

**test/impl/integration/**
- **Purpose:** Test component interactions and Jekyll build
- **Scope:** Multiple components working together
- **Dependencies:** Jekyll, file system, test site
- **Speed:** Medium (seconds per test)
- **Examples:** Build tests, content validation, renderer integration

**test/impl/e2e/**
- **Purpose:** Test complete user workflows in real browser
- **Scope:** Full application from user perspective
- **Dependencies:** Browser, Selenium, built site
- **Speed:** Slow (seconds to minutes per test)
- **Examples:** Navigation tests, page rendering, user interactions

**test/impl/performance/**
- **Purpose:** Test speed and efficiency
- **Scope:** Build times, render times, page load
- **Dependencies:** Large dataset, timing tools
- **Speed:** Slow (minutes per test)
- **Examples:** Build performance, render performance, page load times

**test/migration/**
- **Purpose:** Validate migration script and content quality
- **Scope:** Migration script, migrated content
- **Dependencies:** Test fixtures, file system
- **Speed:** Medium (seconds per test)
- **Examples:** Migration script tests, content validation, thumbnail tests

**test/external/**
- **Purpose:** Test Google Drive integration
- **Scope:** External API interactions
- **Dependencies:** Google API credentials, network
- **Speed:** Slow (seconds per test, network dependent)
- **Examples:** Drive upload, permissions, API authentication
- **Note:** Requires `Google API.json` credentials

**test/tools/**
- **Purpose:** Test utility scripts
- **Scope:** Helper scripts and tools
- **Dependencies:** Minimal
- **Speed:** Fast to medium
- **Examples:** Markdown parser tests, utility function tests

### Test Naming

**File Naming Pattern:** `*_test.rb`

**Examples:**
- `talk_renderer_test.rb` - Tests for TalkRenderer class
- `migration_test.rb` - Tests for migration script
- `content_validation_test.rb` - Tests for content validation

**Test Method Naming:**
```ruby
def test_renders_talk_with_title
  # Test that renderer includes title in output
end

def test_escapes_html_in_content
  # Test that HTML is escaped for security
end

def test_handles_missing_thumbnail
  # Test fallback behavior for missing thumbnails
end
```

**Pattern:** `test_<action>_<condition>` or `test_<behavior>`

**Fixture Naming:**
- `test/fixtures/sample_talks.yml` - Sample talk data
- `test/fixtures/test_talk.md` - Test talk file
- Pattern: Descriptive name indicating content

### Test Patterns

**Setup/Teardown:**
```ruby
class TalkRendererTest < Minitest::Test
  def setup
    @renderer = TalkRenderer.new
    @sample_content = File.read('test/fixtures/test_talk.md')
  end

  def teardown
    # Clean up any created files
    FileUtils.rm_rf('test/tmp')
  end

  def test_something
    # Test code here
  end
end
```

**Assertion Patterns:**
```ruby
# Equality
assert_equal expected, actual

# Truthiness
assert result
refute result

# Inclusion
assert_includes collection, item

# Matching
assert_match /pattern/, string

# Exceptions
assert_raises(ErrorClass) do
  # Code that should raise
end
```

**Mock Usage Guidelines:**
- Use mocks for external services (Google APIs, network)
- Don't mock what you don't own (Jekyll internals)
- Prefer real objects in unit tests when fast
- Use mocks to isolate component under test

**Test Data:**
- Use fixtures for complex data
- Use inline data for simple cases
- Keep test data minimal and focused
- Use realistic data that matches production

## Build Artifacts

### Generated Directories

**_site/**
- **Purpose:** Production build output
- **When created:** Running `bundle exec jekyll build`
- **Git status:** Ignored (in `.gitignore`)
- **Contents:** Complete static site ready for deployment
- **Size:** Varies with content (typically 1-10MB)
- **Cleaning:** Delete to force full rebuild

**_test_site/**
- **Purpose:** Test environment build
- **When created:** Running tests or `bundle exec jekyll build --config _config_test.yml`
- **Git status:** Ignored (in `.gitignore`)
- **Contents:** Site built with test configuration
- **Differences:** Test URLs, test-specific settings
- **Cleaning:** Delete if tests behave strangely

**_perf_test_site/**
- **Purpose:** Performance testing site with many talks
- **When created:** Running performance tests
- **Git status:** Ignored (in `.gitignore`)
- **Contents:** Site with large dataset for performance testing
- **Size:** Larger than production (many test talks)
- **Cleaning:** Delete to free disk space

**.jekyll-cache/**
- **Purpose:** Jekyll build cache for faster incremental builds
- **When created:** First Jekyll build
- **Git status:** Ignored (in `.gitignore`)
- **Contents:** Cached processed files, metadata
- **Size:** Varies (typically 1-5MB)
- **Cleaning:** Delete if builds are stale or behaving oddly

### Cleaning Artifacts

**Clean all build artifacts:**
```bash
rm -rf _site/ _test_site/ _perf_test_site/ .jekyll-cache/
```

**When to clean:**
- Build behaving strangely
- After major configuration changes
- Before deployment (optional, ensures clean build)
- When disk space is low

**What to preserve:**
- Source files (`_talks/`, `assets/`, etc.)
- Configuration files
- Dependencies (`vendor/bundle/`)
- Credentials (`Google API.json`)

**Automated cleaning:**
```bash
# Add to Rakefile
task :clean do
  FileUtils.rm_rf(['_site', '_test_site', '_perf_test_site', '.jekyll-cache'])
end

# Usage
bundle exec rake clean
```

## Naming Conventions

| Type | Convention | Example | Rationale |
|------|-----------|---------|-----------|
| Talk files | `YYYY-MM-DD-kebab-case.md` | `2025-10-01-devconf-coding-fast.md` | Chronological sorting, readable URLs |
| Thumbnails | `{slug}-thumbnail.{ext}` | `devconf-coding-fast-thumbnail.png` | Matches talk file, clear purpose |
| Ruby files | `snake_case.rb` | `talk_renderer.rb` | Ruby community convention |
| Ruby classes | `PascalCase` | `TalkRenderer` | Ruby community convention |
| Ruby methods | `snake_case` | `render_talk` | Ruby community convention |
| CSS classes | `kebab-case` | `.talk-header` | Web standard, readable |
| CSS IDs | `kebab-case` | `#main-content` | Web standard, readable |
| Test files | `*_test.rb` | `talk_renderer_test.rb` | Minitest convention |
| Test methods | `test_snake_case` | `test_renders_title` | Minitest convention |
| Directories | `lowercase` or `snake_case` | `_talks`, `test_site` | Unix convention |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_TALKS` | Ruby convention |
| Environment vars | `SCREAMING_SNAKE_CASE` | `TEST_SINGLE_TALK` | Shell convention |

**Consistency Rules:**
- Stick to conventions within each language/context
- Don't mix conventions (e.g., camelCase in Ruby)
- Use descriptive names over short names
- Avoid abbreviations unless very common

## Anti-Patterns

### What to Avoid

**1. Hardcoded Paths**

**Problem:**
```liquid
<img src="/assets/images/logo.png">
<a href="/talks/my-talk">Link</a>
```

**Why it's bad:**
- Breaks when `baseurl` is set (e.g., `/shownotes`)
- Doesn't work in subdirectory deployments
- Hard to test with different configurations

**Correct approach:**
```liquid
<img src="{{ '/assets/images/logo.png' | relative_url }}">
<a href="{{ '/talks/my-talk' | relative_url }}">Link</a>
```

**2. Inline Styles**

**Problem:**
```html
<div style="color: red; font-size: 16px;">Content</div>
```

**Why it's bad:**
- Can't be overridden by CSS
- Duplicated across files
- Hard to maintain consistent styling
- Increases HTML size

**Correct approach:**
```html
<div class="error-message">Content</div>
```
```css
.error-message {
  color: red;
  font-size: 16px;
}
```

**3. Duplicate Content**

**Problem:**
- Same HTML repeated in multiple layouts
- Same configuration in multiple files
- Same logic in multiple scripts

**Why it's bad:**
- Changes must be made in multiple places
- Easy to miss updates
- Increases maintenance burden
- Leads to inconsistencies

**Correct approach:**
- Use `_includes/` for reusable HTML components
- Use `_config.yml` for shared configuration
- Use `lib/` for shared Ruby logic
- DRY principle: Don't Repeat Yourself

**4. Manual Thumbnail Management**

**Problem:**
- Manually downloading thumbnails from Notist
- Manually resizing and optimizing images
- Manually naming and placing files

**Why it's bad:**
- Time-consuming and error-prone
- Inconsistent naming and sizing
- Easy to forget or make mistakes
- Migration script does this automatically

**Correct approach:**
- Use migration script: `ruby migrate_talk.rb URL`
- Script handles download, naming, placement
- Consistent results every time
- Only manual for non-Notist talks

**5. Direct HTML in Markdown**

**Problem:**
```markdown
<h2>Section Title</h2>
<p>Some content with <strong>bold text</strong>.</p>
<ul>
  <li>Item 1</li>
  <li>Item 2</li>
</ul>
```

**Why it's bad:**
- Harder to read and edit
- Loses markdown simplicity
- Mixing syntaxes is confusing
- Kramdown handles markdown better

**Correct approach:**
```markdown
## Section Title

Some content with **bold text**.

- Item 1
- Item 2
```

**6. Modifying Generated Files**

**Problem:**
- Editing files in `_site/` directly
- Changing generated HTML
- Updating built CSS

**Why it's bad:**
- Changes lost on next build
- Source and output out of sync
- Confusing for other developers
- Wastes time

**Correct approach:**
- Edit source files (`_talks/`, `_layouts/`, `assets/`)
- Rebuild site: `bundle exec jekyll build`
- Changes persist across builds

**7. Committing Build Artifacts**

**Problem:**
- Adding `_site/` to git
- Committing `.jekyll-cache/`
- Tracking generated files

**Why it's bad:**
- Bloats repository size
- Causes merge conflicts
- Unnecessary (GitHub Pages builds automatically)
- Confuses source vs output

**Correct approach:**
- Keep build artifacts in `.gitignore`
- Only commit source files
- Let deployment build from source
- Smaller, cleaner repository

**8. Skipping Tests**

**Problem:**
- Not running tests before committing
- Deploying without validation
- Assuming changes work

**Why it's bad:**
- Breaks production site
- Introduces bugs
- Wastes time debugging later
- Loses confidence in codebase

**Correct approach:**
- Run `bundle exec rake test` before committing
- Run `bundle exec rake quick` during development
- Fix failing tests immediately
- Maintain high test coverage

**9. Ignoring Security**

**Problem:**
- Not escaping user content
- Using `YAML.load` instead of `YAML.safe_load`
- Embedding untrusted URLs
- Committing credentials

**Why it's bad:**
- XSS vulnerabilities
- Code execution risks
- Credential leaks
- Security breaches

**Correct approach:**
- Use `CGI.escapeHTML()` for user content
- Use `YAML.safe_load` for YAML parsing
- Validate URLs before embedding
- Keep `Google API.json` in `.gitignore`
- See [Security](tech.md#security) for details

**10. Inconsistent Naming**

**Problem:**
- Mixing conventions: `myFile.rb`, `my-file.rb`, `MyFile.rb`
- Abbreviations: `tlk.md`, `conf.md`
- Unclear names: `file1.md`, `temp.rb`

**Why it's bad:**
- Hard to find files
- Confusing for collaborators
- Breaks patterns and expectations
- Looks unprofessional

**Correct approach:**
- Follow [Naming Conventions](#naming-conventions) table
- Use descriptive names
- Be consistent within each context
- Use full words, not abbreviations
