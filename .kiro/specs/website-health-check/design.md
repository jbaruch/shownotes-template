# Design Document

## Overview

The production website (speaking.jbaru.ch) is missing critical content that displays correctly on local builds. Investigation reveals that while the site uses GitHub Actions for deployment (which should support custom Jekyll plugins), the production build is not properly extracting metadata from talk markdown files. Additionally, the sample-talk.md template file is appearing on production and needs to be excluded.

## Root Cause Analysis

### Issue 1: Missing Content Extraction on Production

**Symptoms:**
- Production shows generic slugified titles (e.g., "Dev2next 2025 Robocoders Judgment Day") instead of proper talk titles
- Missing "Highlighted Presentations" section
- Missing conference names, dates, and video status metadata
- Talk pages show only title and "Video Coming Soon" with no content

**Root Cause:**
The site relies on a custom Jekyll plugin (`_plugins/markdown_parser.rb`) that extracts metadata from markdown content and stores it in `extracted_*` variables (extracted_title, extracted_conference, extracted_date, etc.). While GitHub Actions builds should support custom plugins, there may be an issue with:

1. **Plugin execution timing** - The plugin may not be running during the production build
2. **Build configuration differences** - The deploy workflow uses `--baseurl "${{ steps.pages.outputs.base_path }}"` which might affect plugin behavior
3. **Jekyll environment** - Production environment (`JEKYLL_ENV: production`) might have different plugin loading behavior

**Evidence:**
- Local builds work correctly (plugin runs successfully)
- Production layouts reference `page.extracted_title`, `page.extracted_conference`, etc.
- When these variables are undefined, Liquid templates fall back to `page.title` (which is the slugified filename)
- The `_plugins/markdown_parser.rb` file exists and is not in the exclude list

### Issue 2: Sample Talk Appearing on Production

**Symptoms:**
- `_talks/sample-talk.md` appears in the production talks list
- This is a template file meant for documentation, not a real talk

**Root Cause:**
The sample talk file is tracked in git and included in the `_talks` collection. Jekyll processes all files in the collection directory unless explicitly excluded.

**Current State:**
- `.gitignore` does not exclude `_talks/sample-talk.md`
- `_config.yml` exclude list does not include the sample talk
- The file is committed to the repository

## Architecture

### Current Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions Workflow                  │
│                                                              │
│  1. Checkout code                                           │
│  2. Setup Ruby 3.4.5                                        │
│  3. Bundle install (with cache)                             │
│  4. Run quick tests                                         │
│  5. Jekyll build --baseurl "${{ steps.pages.outputs.base_path }}" │
│  6. Upload artifact                                         │
│  7. Deploy to GitHub Pages                                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      Jekyll Build Process                    │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  _plugins/markdown_parser.rb                         │  │
│  │  - Runs at :high priority during generate phase     │  │
│  │  - Extracts metadata from markdown content          │  │
│  │  - Sets extracted_* variables on each talk document │  │
│  └──────────────────────────────────────────────────────┘  │
│                            │                                 │
│                            ▼                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Liquid Template Rendering                           │  │
│  │  - index.md uses {{ talk.extracted_title }}          │  │
│  │  - _layouts/talk.html uses {{ page.extracted_* }}    │  │
│  │  - Falls back to {{ page.title }} if undefined      │  │
│  └──────────────────────────────────────────────────────┘  │
│                            │                                 │
│                            ▼                                 │
│                      _site/ output                          │
└─────────────────────────────────────────────────────────────┘
```

### Problem Areas

1. **Plugin Execution**: The markdown_parser.rb plugin may not be executing properly in the production build
2. **Baseurl Override**: The deploy workflow overrides baseurl, which might affect plugin behavior
3. **Sample Talk Inclusion**: No mechanism to exclude template files from production builds

## Components and Interfaces

### Component 1: Markdown Parser Plugin

**File:** `_plugins/markdown_parser.rb`

**Purpose:** Extract metadata from talk markdown files and populate extracted_* variables

**Key Methods:**
- `generate(site)` - Main entry point, processes all talks
- `extract_title_from_content(content)` - Extracts H1 heading
- `extract_metadata_from_content(content, field)` - Extracts **Field:** patterns
- `extract_description_from_content(content)` - Extracts first paragraph
- `extract_abstract_from_content(content)` - Extracts ## Abstract section
- `extract_resources_from_content(content)` - Extracts ## Resources section

**Current Behavior:**
- Runs during Jekyll's generate phase with :high priority
- Processes each document in the talks collection
- Sets data on `doc.data['extracted_*']` hash

**Issues:**
- May not be running in production environment
- No error logging or debugging output
- No fallback mechanism if extraction fails

### Component 2: Layout Templates

**Files:** `_layouts/default.html`, `_layouts/talk.html`, `index.md`

**Dependencies:** Relies on extracted_* variables from markdown parser plugin

**Fallback Behavior:**
- Uses `{{ page.extracted_title | default: page.title }}` pattern
- When extracted_title is undefined, falls back to page.title (slugified filename)
- This explains why production shows "Dev2next 2025 Robocoders Judgment Day" instead of proper titles

### Component 3: GitHub Actions Deploy Workflow

**File:** `.github/workflows/deploy.yml`

**Current Configuration:**
```yaml
- name: Build with Jekyll
  run: bundle exec jekyll build --baseurl "${{ steps.pages.outputs.base_path }}"
  env:
    JEKYLL_ENV: production
```

**Potential Issues:**
- Baseurl override might affect plugin loading
- JEKYLL_ENV=production might change plugin behavior
- No explicit plugin verification step

### Component 4: Jekyll Configuration

**File:** `_config.yml`

**Relevant Settings:**
```yaml
url: "https://speaking.jbaru.ch"
baseurl: ""
plugins:
  - jekyll-feed
  - jekyll-sitemap
  - jekyll-seo-tag
exclude:
  - Gemfile
  - Gemfile.lock
  - vendor/
  - test/
  # ... but NOT _talks/sample-talk.md
```

**Issues:**
- Custom plugins (in _plugins/) are not listed in plugins array (they're auto-loaded)
- Sample talk not in exclude list
- No production-specific configuration

## Data Models

### Talk Document Data Structure

```ruby
{
  # Jekyll-provided fields
  'title' => 'sample-talk',  # Slugified from filename
  'path' => '_talks/2025-10-01-dev2next-2025-robocoders-judgment-day.md',
  'url' => '/talks/2025-10-01-dev2next-2025-robocoders-judgment-day/',
  'content' => '# RoboCoders: Judgment Day...',  # Full markdown content
  
  # Plugin-extracted fields (should be present but missing on production)
  'extracted_title' => 'RoboCoders: Judgment Day – AI IDEs Face Off',
  'extracted_conference' => 'Dev2Next 2025',
  'extracted_date' => '2025-10-01',
  'extracted_slides' => 'https://drive.google.com/...',
  'extracted_video' => 'https://youtube.com/...',
  'extracted_description' => 'Can AI-powered IDEs take software development...',
  'extracted_abstract' => 'Full abstract text...',
  'extracted_resources' => '- [Resource](URL)\n- [Another](URL)',
  'extracted_presentation_context' => 'A presentation at Dev2Next 2025...'
}
```

### Expected vs Actual on Production

**Local Build (Working):**
```ruby
talk.data['extracted_title'] # => "RoboCoders: Judgment Day – AI IDEs Face Off"
talk.data['extracted_conference'] # => "Dev2Next 2025"
```

**Production Build (Broken):**
```ruby
talk.data['extracted_title'] # => nil (undefined)
talk.data['extracted_conference'] # => nil (undefined)
# Falls back to:
talk.data['title'] # => "2025-10-01-dev2next-2025-robocoders-judgment-day"
```

## Solution Design

### Solution 1: Fix Plugin Execution on Production

**Approach A: Verify Plugin is Running**

Add debugging output to the plugin to confirm it's executing:

```ruby
def generate(site)
  puts "DEBUG: MarkdownTalkProcessor running in #{Jekyll.env} environment"
  talks_collection = site.collections['talks']
  puts "DEBUG: Found #{talks_collection.docs.size} talks" if talks_collection
  
  # ... existing code ...
end
```

**Approach B: Ensure Plugin Runs Before Template Rendering**

The plugin already has `priority :high`, but we should verify the execution order:

```ruby
class MarkdownTalkProcessor < Generator
  safe true
  priority :highest  # Change from :high to :highest
  
  # ... existing code ...
end
```

**Approach C: Add Fallback in Templates**

Modify templates to handle missing extracted_* variables more gracefully:

```liquid
{% assign title = page.extracted_title | default: page.title %}
{% if title contains "-" and title.size > 30 %}
  {% comment %}Likely a slugified filename, try to humanize it{% endcomment %}
  {% assign title = title | replace: "-", " " | capitalize %}
{% endif %}
```

**Recommended Solution:**
1. Add debugging output to confirm plugin execution
2. Check if baseurl override affects plugin loading
3. Verify JEKYLL_ENV=production doesn't disable custom plugins
4. Add error handling and logging to plugin

### Solution 2: Exclude Sample Talk from Production

**Approach A: Add to .gitignore**

```gitignore
# Template files (not for production)
_talks/sample-talk.md
```

**Pros:**
- Prevents accidental commits
- File won't be in repository at all

**Cons:**
- Developers need to create it locally from documentation
- Loses version control for the template

**Approach B: Add to Jekyll exclude list**

```yaml
# _config.yml
exclude:
  - Gemfile
  - Gemfile.lock
  - vendor/
  - test/
  - _talks/sample-talk.md  # Add this
```

**Pros:**
- File stays in repository for reference
- Jekyll won't process it during build
- Version controlled

**Cons:**
- File is still in git history
- Might be confusing (file exists but doesn't appear)

**Approach C: Move to docs/ directory**

```
docs/
  └── templates/
      └── sample-talk.md
```

**Pros:**
- Clear separation of documentation vs content
- Still version controlled
- Won't be processed by Jekyll (docs/ is in exclude list)

**Cons:**
- Requires updating documentation references
- More file reorganization

**Recommended Solution:**
Use Approach C (move to docs/templates/) because:
- Clearest intent (it's a template, not content)
- Maintains version control
- Follows existing project structure (docs/ already exists)
- Won't be processed by Jekyll

### Solution 3: Add Production Health Tests

Create automated tests that verify production site health:

**Test Categories:**

1. **Content Extraction Tests**
   - Verify extracted_* variables are present
   - Verify titles are not slugified filenames
   - Verify metadata is properly formatted

2. **Production Parity Tests**
   - Compare local build output to production
   - Verify same number of talks
   - Verify same content structure

3. **Sample Talk Exclusion Tests**
   - Verify sample-talk.md doesn't appear in production
   - Verify /talks/sample-talk/ returns 404

**Implementation:**

```ruby
# test/impl/e2e/production_health_test.rb
class ProductionHealthTest < Minitest::Test
  def test_production_site_loads
    response = Net::HTTP.get_response(URI('https://speaking.jbaru.ch'))
    assert_equal '200', response.code
  end
  
  def test_production_has_highlighted_presentations
    html = Net::HTTP.get(URI('https://speaking.jbaru.ch'))
    assert_includes html, 'Highlighted Presentations'
  end
  
  def test_production_talk_has_proper_title
    html = Net::HTTP.get(URI('https://speaking.jbaru.ch/talks/2025-10-01-dev2next-2025-robocoders-judgment-day/'))
    assert_includes html, 'RoboCoders: Judgment Day'
    refute_includes html, 'Dev2next 2025 Robocoders Judgment Day'  # Not the slugified version
  end
  
  def test_sample_talk_not_on_production
    html = Net::HTTP.get(URI('https://speaking.jbaru.ch'))
    refute_includes html, 'Your Amazing Talk Title'
    refute_includes html, '/talks/sample-talk/'
  end
end
```

## Error Handling

### Plugin Errors

**Current State:** No error handling in markdown_parser.rb

**Proposed:**
```ruby
def generate(site)
  talks_collection = site.collections['talks']
  return unless talks_collection && talks_collection.docs
  
  talks_collection.docs.each do |doc|
    begin
      content = doc.content
      doc.data['extracted_title'] = extract_title_from_content(content)
      # ... other extractions ...
    rescue => e
      Jekyll.logger.error "MarkdownTalkProcessor", "Failed to process #{doc.path}: #{e.message}"
      # Set fallback values
      doc.data['extracted_title'] ||= doc.data['title']
      doc.data['extracted_conference'] ||= 'Unknown Conference'
    end
  end
end
```

### Template Errors

**Current State:** Templates use `| default:` filter for fallbacks

**Proposed:** Add more robust fallbacks and error messages

```liquid
{% if page.extracted_title %}
  <h1>{{ page.extracted_title }}</h1>
{% elsif page.title %}
  <h1>{{ page.title | replace: "-", " " | capitalize }}</h1>
  {% comment %}TODO: This is a fallback, extracted_title should be present{% endcomment %}
{% else %}
  <h1>Untitled Talk</h1>
{% endif %}
```

## Testing Strategy

### Unit Tests

**Target:** Individual extraction methods in markdown_parser.rb

```ruby
# test/impl/unit/markdown_parser_test.rb
class MarkdownParserTest < Minitest::Test
  def test_extract_title_from_content
    content = "# My Amazing Talk\n\n**Conference:** DevConf"
    parser = Jekyll::MarkdownTalkProcessor.new
    title = parser.send(:extract_title_from_content, content)
    assert_equal 'My Amazing Talk', title
  end
  
  def test_extract_title_handles_missing_h1
    content = "**Conference:** DevConf"
    parser = Jekyll::MarkdownTalkProcessor.new
    title = parser.send(:extract_title_from_content, content)
    assert_equal 'Untitled Talk', title
  end
end
```

### Integration Tests

**Target:** Full Jekyll build with plugin execution

```ruby
# test/impl/integration/plugin_execution_test.rb
class PluginExecutionTest < Minitest::Test
  def test_plugin_extracts_metadata_during_build
    site = build_test_site
    talk = site.collections['talks'].docs.first
    
    assert talk.data['extracted_title'], 'Plugin should extract title'
    assert talk.data['extracted_conference'], 'Plugin should extract conference'
    refute_equal talk.data['title'], talk.data['extracted_title'], 
                 'Extracted title should differ from slugified title'
  end
end
```

### End-to-End Tests

**Target:** Production website behavior

```ruby
# test/impl/e2e/production_parity_test.rb
class ProductionParityTest < Minitest::Test
  def test_local_and_production_have_same_talks
    local_html = File.read('_site/index.html')
    prod_html = Net::HTTP.get(URI('https://speaking.jbaru.ch'))
    
    local_talks = extract_talk_titles(local_html)
    prod_talks = extract_talk_titles(prod_html)
    
    assert_equal local_talks.sort, prod_talks.sort
  end
end
```

### Property-Based Tests

Not applicable for this feature - the issues are deterministic and don't require property-based testing.

## Implementation Plan

### Phase 1: Investigation and Diagnosis

1. Add debugging output to markdown_parser.rb plugin
2. Trigger a production deployment
3. Check GitHub Actions logs for plugin execution
4. Verify extracted_* variables are being set
5. Document findings

### Phase 2: Fix Plugin Execution

1. If plugin isn't running: Fix plugin loading/execution
2. If plugin is running but failing: Add error handling and logging
3. If baseurl is causing issues: Adjust deploy workflow
4. Test locally with production-like configuration
5. Deploy and verify fix

### Phase 3: Exclude Sample Talk

1. Create `docs/templates/` directory
2. Move `_talks/sample-talk.md` to `docs/templates/sample-talk.md`
3. Update documentation to reference new location
4. Add to .gitignore: `_talks/sample-talk.md` (prevent future accidents)
5. Commit and deploy

### Phase 4: Add Production Health Tests

1. Create `test/impl/e2e/production_health_test.rb`
2. Add tests for:
   - Homepage loads successfully
   - Highlighted Presentations section exists
   - Talk pages have proper titles (not slugified)
   - Sample talk doesn't appear
3. Add to CI workflow (run after deployment)
4. Document test expectations

### Phase 5: Improve Error Handling

1. Add try/catch blocks to plugin extraction methods
2. Add Jekyll.logger statements for debugging
3. Set fallback values when extraction fails
4. Add template warnings for missing data
5. Test error scenarios

## Deployment Strategy

### Pre-Deployment Checklist

- [ ] Plugin debugging output added
- [ ] Local build matches expected behavior
- [ ] Tests pass locally
- [ ] Sample talk moved to docs/templates/
- [ ] Documentation updated

### Deployment Steps

1. Merge changes to main branch
2. GitHub Actions automatically triggers deploy workflow
3. Monitor build logs for plugin execution
4. Verify production site after deployment
5. Run production health tests
6. Rollback if issues detected

### Rollback Plan

If deployment fails:
1. Revert commit in git
2. Push to main branch
3. Wait for automatic redeployment
4. Investigate issues in separate branch

### Monitoring

**Metrics to Track:**
- Build success rate
- Plugin execution time
- Number of talks with missing extracted_* data
- Production health test pass rate

**Alerts:**
- Build failures
- Production health test failures
- Missing content on production

## Security Considerations

### Plugin Safety

The markdown_parser.rb plugin:
- Only reads markdown content (no file writes)
- Doesn't execute user-provided code
- Uses safe string operations
- No external network calls

**Risk:** Low - Plugin is read-only and processes trusted content

### Template Injection

Templates use Liquid's auto-escaping:
```liquid
{{ page.extracted_title }}  <!-- Auto-escaped -->
```

**Risk:** Low - Liquid escapes by default

### Sample Talk Exposure

The sample talk contains placeholder content:
- No sensitive information
- Generic example data
- Safe to be public

**Risk:** Minimal - Just looks unprofessional

## Performance Considerations

### Plugin Performance

**Current:**
- Runs once during build
- Processes ~60 talk files
- Each file: ~5-10 regex operations
- Total time: < 1 second

**Impact:** Negligible - Plugin is fast and runs only at build time

### Build Time

**Current Build Time:** ~30-60 seconds
- Ruby setup: ~10s
- Bundle install (cached): ~5s
- Tests: ~10s
- Jekyll build: ~10s
- Upload/deploy: ~10s

**After Changes:** No significant impact expected

### Page Load Performance

**No Impact:** Changes only affect build process, not runtime performance

## Future Enhancements

### 1. Smarter Fallbacks

If plugin fails, use AI/NLP to extract metadata from content:
- Parse natural language dates
- Identify conference names from context
- Extract titles from first sentence

### 2. Build Verification

Add post-build verification step:
```yaml
- name: Verify build output
  run: |
    ruby scripts/verify_build.rb _site/
    # Checks for missing extracted_* data
    # Fails build if issues found
```

### 3. Content Validation

Pre-commit hooks to validate talk files:
- Ensure H1 heading exists
- Verify required metadata fields
- Check for common formatting issues

### 4. Production Monitoring

Set up monitoring for:
- Content extraction success rate
- Missing metadata alerts
- Build failure notifications

## Open Questions

1. **Why is the plugin not running on production?**
   - Need to check GitHub Actions logs
   - Verify plugin is being loaded
   - Check for environment-specific issues

2. **Does baseurl override affect plugin execution?**
   - Test locally with `--baseurl /test`
   - Compare plugin behavior with/without baseurl

3. **Should we keep sample-talk.md in git at all?**
   - Option A: Move to docs/templates/ (recommended)
   - Option B: Remove entirely and document in README
   - Option C: Keep but add to exclude list

4. **Do we need a staging environment?**
   - Would help catch these issues before production
   - Could deploy to GitHub Pages preview environment
   - Trade-off: Added complexity vs safety

## Decision Log

### Decision 1: Move Sample Talk to docs/templates/

**Date:** 2025-01-08
**Decision:** Move `_talks/sample-talk.md` to `docs/templates/sample-talk.md`
**Rationale:**
- Keeps file in version control for reference
- Clear separation of templates vs content
- Won't be processed by Jekyll (docs/ is excluded)
- Follows existing project structure

**Alternatives Considered:**
- Add to .gitignore: Loses version control
- Add to exclude list: Confusing (file exists but hidden)

### Decision 2: Add Production Health Tests

**Date:** 2025-01-08
**Decision:** Create E2E tests that verify production site health
**Rationale:**
- Catches deployment issues before users see them
- Provides confidence in production deployments
- Documents expected behavior
- Can run automatically after deployment

**Alternatives Considered:**
- Manual verification: Error-prone and time-consuming
- No testing: Risky, issues go unnoticed

### Decision 3: Add Plugin Debugging

**Date:** 2025-01-08
**Decision:** Add Jekyll.logger statements to plugin for debugging
**Rationale:**
- Need visibility into plugin execution
- Helps diagnose production issues
- Minimal performance impact
- Can be removed after issue is resolved

**Alternatives Considered:**
- No debugging: Can't diagnose issues
- Verbose logging: Too much noise in logs
