# Content Inventory

This document tracks all unique information from the existing steering files, identifies duplications, and categorizes content for refactoring.

## Duplications Found

### Configuration Files
- **tech.md**: Lists `_config.yml`, `_config_test.yml`, `Gemfile`, `Rakefile` with brief descriptions
- **structure.md**: Lists same files under "Important Files" with slightly different descriptions
- **Resolution**: Keep detailed descriptions in tech.md (Configuration Files section), reference from structure.md

### migrate_talk.rb
- **tech.md**: Shows command examples under Migration section
- **structure.md**: Lists as "Important Files" - "Main migration script (single source of truth)"
- **Resolution**: Commands stay in tech.md, file location/purpose in structure.md

### Testing Information
- **tech.md**: Test commands and categories
- **structure.md**: Test structure and organization
- **Resolution**: Commands in tech.md, directory structure in structure.md

### Security (XSS protection)
- **tech.md**: "XSS protection via HTML escaping in renderers"
- **structure.md**: "XSS protection" mentioned in Libraries section for talk_renderer.rb
- **Resolution**: Consolidate in tech.md Security section, reference from structure.md

### Jekyll/Kramdown/Bundler
- **tech.md**: Listed as core technologies
- **structure.md**: Mentioned in Build System context
- **Resolution**: Keep in tech.md, remove from structure.md

## Content Categorization

### PRODUCT.MD Content (Workflows & Features)

**Current Content:**
- Product overview and description ✓
- Purpose statement ✓
- Key features list ✓
- Target users ✓
- Core workflows (high-level only) - NEEDS EXPANSION

**Missing Content:**
- Detailed workflow steps with commands
- Prerequisites for each workflow
- Expected outcomes and validation
- Common issues and troubleshooting
- Decision guides (when to use which approach)
- Workflow variations

### TECH.MD Content (Commands & Technical Operations)

**Current Content:**
- Core technologies with versions ✓
- Key dependencies ✓
- Development commands ✓
- Testing commands ✓
- Migration commands ✓
- Build system overview ✓
- Configuration files list ✓
- Security considerations ✓

**Missing Content:**
- Purpose/rationale for each technology choice
- When to run each command
- Expected output for commands
- Command prerequisites
- Troubleshooting section (dependency issues, build failures, migration problems, test issues)
- Performance optimization guidance
- Detailed configuration file documentation

### STRUCTURE.MD Content (Organization & Patterns)

**Current Content:**
- Directory tree with comments ✓
- Talk file patterns ✓
- Thumbnail patterns ✓
- Layout patterns ✓
- Library descriptions ✓
- Talk file structure example ✓
- Configuration overview ✓
- Testing structure ✓
- Build artifacts ✓
- Important files list ✓
- Naming conventions ✓

**Missing Content:**
- Rationale for naming conventions
- Good vs bad examples
- Frontmatter schema details
- Markdown conventions
- Test naming patterns
- Test patterns (setup/teardown, assertions)
- Anti-patterns section
- Why certain patterns exist

## Information Mapping

### Core Technologies (tech.md)
- Jekyll 4.3+: Static site generator
- Ruby 3.4+: Runtime environment
- Liquid: Template engine
- Kramdown: Markdown parser with GFM support
- Bundler: Dependency management

### Dependencies (tech.md)
**Production:**
- jekyll-feed: RSS feed generation
- jekyll-sitemap: Sitemap generation
- jekyll-seo-tag: SEO meta tags
- google-apis-slides_v1: Google Slides API
- google-apis-drive_v3: Google Drive API
- nokogiri: HTML/XML parsing

**Development:**
- minitest: Testing framework
- capybara + selenium-webdriver: E2E testing

### Commands (tech.md)
**Development:**
- `bundle install` - Install dependencies
- `bundle exec jekyll serve --livereload` - Start local server with live reload
- `bundle exec jekyll build` - Build site
- `bundle exec jekyll build --config _config_test.yml` - Build with test config

**Testing:**
- `bundle exec rake test` - Run all tests
- `bundle exec ruby test/run_tests.rb` - Alternative to run all tests
- `bundle exec rake test:unit` - Run unit tests
- `bundle exec rake test:integration` - Run integration tests
- `bundle exec rake test:e2e` - Run E2E tests
- `bundle exec rake test:migration` - Run migration tests
- `TEST_SINGLE_TALK=talk-slug bundle exec ruby test/migration/migration_test.rb` - Test single talk
- `bundle exec rake quick` - Quick essential tests only

**Migration:**
- `ruby migrate_talk.rb https://noti.st/speaker/talk-slug` - Migrate single talk
- `ruby migrate_talk.rb --speaker https://noti.st/speaker` - Migrate all talks
- `ruby migrate_talk.rb URL --skip-tests` - Skip tests for faster migration

### File Patterns (structure.md)
**Talk Files:**
- Location: `_talks/`
- Naming: `YYYY-MM-DD-conference-talk-title.md`
- Format: YAML frontmatter + Markdown content
- Frontmatter: Minimal (only `layout: talk`)

**Thumbnails:**
- Location: `assets/images/thumbnails/`
- Naming: `{talk-slug}-thumbnail.png`
- Format: PNG or JPG, ~400x300px recommended
- Fallback: `placeholder-thumbnail.svg`

**Layouts:**
- Location: `_layouts/`
- Main layout: `talk.html`
- Uses: Liquid templating with site.speaker configuration

**Libraries:**
- `talk_renderer.rb`: Full-featured renderer with Google Slides/YouTube embed support, XSS protection, resource management
- `simple_talk_renderer.rb`: Lightweight version for testing without heavy dependencies

### Directory Structure (structure.md)
- `_talks/`: Talk content (markdown files)
- `_layouts/`: Jekyll page templates
- `_includes/`: Reusable template components
- `_plugins/`: Custom Jekyll plugins
- `lib/`: Core Ruby libraries
- `assets/`: Static assets (css, images, thumbnails)
- `test/`: Test suite (impl, migration, external, tools)
- `utils/`: Utility scripts (migration, google_drive)
- `docs/`: Documentation
- `_site/`: Generated site (git-ignored)
- `_test_site/`: Test build output
- `_perf_test_site/`: Performance test site
- `migrate_talk.rb`: Main migration script
- `_config.yml`: Jekyll configuration
- `Rakefile`: Build and test tasks

### Naming Conventions (structure.md)
- Talk files: Lowercase with hyphens, date-prefixed
- Thumbnails: Match talk filename + `-thumbnail` suffix
- Ruby files: Snake_case
- CSS classes: Kebab-case
- Test files: `*_test.rb` suffix

### Security (tech.md)
- XSS protection via HTML escaping in renderers
- Safe YAML parsing with `YAML.safe_load`
- URL validation for external resources
- Service account authentication for Google APIs
- `.gitignore` excludes `Google API.json` credentials

### Features (product.md)
- Mobile-first design optimized for conference networks
- Automated migration from Notist platform
- Google Drive integration for slide hosting
- Automatic thumbnail generation and management
- Zero-dependency deployment via GitHub Pages
- SEO optimization with structured data
- XSS protection and WCAG compliance

### Target Users (product.md)
Conference speakers who want to:
- Share talk resources easily during presentations
- Migrate existing talks from Notist
- Maintain a professional portfolio of presentations
- Provide accessible, mobile-friendly content to attendees

### High-Level Workflows (product.md)
1. Quick Start: Fork repo, configure speaker profile, add talks manually
2. Automated Migration: Use migration script to import talks from Notist
3. Manual Creation: Create markdown files with frontmatter and content
4. Deployment: Push to GitHub Pages or deploy to custom hosting

## Refactoring Strategy

1. **Eliminate Duplications**: Configuration files, testing info, security mentions
2. **Expand Workflows**: Add detailed steps, prerequisites, outcomes, troubleshooting
3. **Add Missing Sections**: Troubleshooting, performance, anti-patterns, rationale
4. **Enhance Examples**: Add expected output, good/bad examples, complete examples
5. **Add Cross-References**: Link between files instead of duplicating
6. **Improve Organization**: Group related information, use consistent formatting
