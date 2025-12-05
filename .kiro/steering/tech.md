# Technology Stack

## Core Technologies

- **Jekyll 4.3+**: Static site generator - chosen for zero-runtime dependencies, GitHub Pages compatibility, and mature ecosystem
- **Ruby 3.4+**: Runtime environment - required by Jekyll, provides excellent scripting capabilities for migration tools
- **Liquid**: Template engine - Jekyll's built-in templating language, simple syntax for non-developers
- **Kramdown**: Markdown parser with GFM support - provides GitHub-flavored markdown compatibility and syntax highlighting
- **Bundler**: Dependency management - standard Ruby dependency manager, ensures consistent gem versions

## Dependencies

### Production Dependencies

- **jekyll-feed**: RSS feed generation - automatically creates Atom feed for talk updates
- **jekyll-sitemap**: Sitemap generation - creates XML sitemap for search engine indexing
- **jekyll-seo-tag**: SEO meta tags - adds Open Graph, Twitter Card, and schema.org markup
- **google-apis-slides_v1**: Google Slides API - enables slide upload and management during migration
- **google-apis-drive_v3**: Google Drive API - provides file hosting and permission management for slides
- **nokogiri**: HTML/XML parsing - used for scraping Notist content and validating generated HTML

### Development Dependencies

- **minitest**: Testing framework - Ruby's standard testing library, simple and fast
- **capybara**: Browser automation - enables end-to-end testing of generated site
- **selenium-webdriver**: Browser driver - powers Capybara for real browser testing

## Command Reference

### Development Commands

#### bundle install

**Purpose:** Install all Ruby gem dependencies specified in Gemfile.

**When to run:**
- First time setting up the project
- After pulling changes that update Gemfile or Gemfile.lock
- When dependency errors occur

**Usage:**
```bash
bundle install
```

**Expected output:**
```
Fetching gem metadata from https://rubygems.org/
Resolving dependencies...
Bundle complete! X Gemfile dependencies, Y gems now installed.
```

**Common issues:** See [Dependency Issues](#dependency-issues)

#### bundle exec jekyll serve --livereload

**Purpose:** Start local development server with automatic browser refresh on file changes.

**When to run:**
- During active development
- When previewing changes before deployment
- When testing talk content locally

**Usage:**
```bash
bundle exec jekyll serve --livereload
```

**Expected output:**
```
Configuration file: _config.yml
            Source: /path/to/shownotes
       Destination: /path/to/shownotes/_site
 Incremental build: disabled
      Generating...
                    done in X.X seconds.
 Auto-regeneration: enabled for '/path/to/shownotes'
LiveReload address: http://127.0.0.1:35729
    Server address: http://127.0.0.1:4000/
  Server running... press ctrl-c to stop.
```

**Access:** Open http://localhost:4000 in browser

**Common issues:** See [Build Issues](#build-issues)

#### bundle exec jekyll build

**Purpose:** Generate static site files for production deployment.

**When to run:**
- Before deploying to custom hosting
- When testing production build locally
- When debugging build issues

**Usage:**
```bash
bundle exec jekyll build
```

**Expected output:**
```
Configuration file: _config.yml
            Source: /path/to/shownotes
       Destination: /path/to/shownotes/_site
 Incremental build: disabled
      Generating...
                    done in X.X seconds.
```

**Result:** Static site generated in `_site/` directory

**Common issues:** See [Build Issues](#build-issues)

#### bundle exec jekyll build --config _config_test.yml

**Purpose:** Build site with test configuration for automated testing.

**When to run:**
- During test suite execution (automated)
- When debugging test-specific build issues
- When validating test configuration

**Usage:**
```bash
bundle exec jekyll build --config _config_test.yml
```

**Expected output:** Similar to regular build, but uses test configuration and outputs to `_test_site/`

**Differences from production:**
- Uses test-specific URLs and paths
- May include test-only content
- Outputs to `_test_site/` instead of `_site/`

### Testing Commands

#### bundle exec rake test

**Purpose:** Run complete test suite including unit, integration, E2E, and migration tests.

**When to run:**
- Before committing changes
- Before deploying to production
- After refactoring code
- When validating full system functionality

**Usage:**
```bash
bundle exec rake test
```

**Alternative:**
```bash
bundle exec ruby test/run_tests.rb
```

**Expected output:**
```
Run options: --seed XXXXX

# Running:

.................................................

Finished in X.XXs, XX.XX runs/s, XX.XX assertions/s.

XX runs, XX assertions, 0 failures, 0 errors, 0 skips
```

**Duration:** 2-5 minutes depending on system

**Common issues:** See [Test Issues](#test-issues)

#### bundle exec rake test:unit

**Purpose:** Run unit tests only - fast tests for individual components.

**When to run:**
- During active development
- When testing specific component changes
- When you need quick feedback

**Usage:**
```bash
bundle exec rake test:unit
```

**Expected output:** Similar to full test suite but faster (10-30 seconds)

**Coverage:** Tests individual Ruby classes and methods in isolation

#### bundle exec rake test:integration

**Purpose:** Run integration tests - validates Jekyll build and content rendering.

**When to run:**
- After changing templates or layouts
- When modifying content structure
- Before deployment

**Usage:**
```bash
bundle exec rake test:integration
```

**Expected output:** Test results showing Jekyll build validation and content checks

**Coverage:** Tests Jekyll build process, content validation, renderer integration

#### bundle exec rake test:e2e

**Purpose:** Run end-to-end tests - validates complete user workflows in real browser.

**When to run:**
- Before major releases
- After significant UI changes
- When validating full user experience

**Usage:**
```bash
bundle exec rake test:e2e
```

**Expected output:** Browser automation tests with Capybara/Selenium

**Duration:** Slower than other tests (1-2 minutes)

**Prerequisites:** Chrome or Firefox browser installed

**Common issues:** See [Test Issues](#test-issues) for browser driver problems

#### bundle exec rake test:migration

**Purpose:** Run migration-specific tests - validates migration script and content quality.

**When to run:**
- After running migration
- When debugging migration issues
- Before committing migrated content

**Usage:**
```bash
bundle exec rake test:migration
```

**Expected output:** Validation of migrated talk files, thumbnails, and content structure

**Coverage:** Tests migration script functionality and migrated content quality

#### TEST_SINGLE_TALK=talk-slug bundle exec ruby test/migration/migration_test.rb

**Purpose:** Test migration of a single specific talk.

**When to run:**
- When debugging specific talk migration issues
- When validating individual talk content
- During migration troubleshooting

**Usage:**
```bash
TEST_SINGLE_TALK=2025-10-01-devconf-coding-fast bundle exec ruby test/migration/migration_test.rb
```

**Expected output:** Test results for specified talk only

**Note:** Use talk filename without `.md` extension

#### bundle exec rake quick

**Purpose:** Run essential tests only - fast validation of core functionality.

**When to run:**
- During rapid development cycles
- When you need quick validation
- Before committing small changes

**Usage:**
```bash
bundle exec rake quick
```

**Expected output:** Subset of tests focusing on critical functionality

**Duration:** 30-60 seconds

**Trade-off:** Speed vs coverage - use for quick checks, run full suite before deployment

### Migration Commands

#### ruby migrate_talk.rb https://noti.st/speaker/talk-slug

**Purpose:** Migrate a single talk from Notist with slides, thumbnail, and resources.

**When to run:**
- First migration to test setup
- Adding individual talks
- When re-migrating specific talks

**Prerequisites:**
- `Google API.json` credentials file in project root
- Google Drive and Slides APIs enabled
- Valid Notist talk URL

**Usage:**
```bash
ruby migrate_talk.rb https://noti.st/speaker/talk-slug
```

**Expected output:**
```
Fetching talk from Notist...
Downloading slides...
Uploading to Google Drive...
Downloading thumbnail...
Creating markdown file...
Running tests...
✓ Migration complete: _talks/YYYY-MM-DD-conference-talk-title.md
```

**Result:**
- Markdown file created in `_talks/`
- Thumbnail downloaded to `assets/images/thumbnails/`
- Slides uploaded to Google Drive
- Tests run automatically

**Duration:** 1-3 minutes per talk

**Common issues:** See [Migration Issues](#migration-issues)

#### ruby migrate_talk.rb --speaker https://noti.st/speaker

**Purpose:** Migrate all talks from a Notist speaker profile.

**When to run:**
- Initial bulk migration
- When migrating entire portfolio
- After testing single talk migration successfully

**Prerequisites:** Same as single talk migration

**Usage:**
```bash
ruby migrate_talk.rb --speaker https://noti.st/speaker
```

**Expected output:** Progress for each talk, similar to single talk output repeated

**Duration:** 1-3 minutes per talk × number of talks

**Recommendation:** Test with single talk first, then migrate all

#### ruby migrate_talk.rb URL --skip-tests

**Purpose:** Migrate talk(s) without running tests - faster but less validation.

**When to run:**
- When migrating many talks and will run tests separately
- When tests are failing but migration works
- During rapid iteration on migration script

**Usage:**
```bash
ruby migrate_talk.rb https://noti.st/speaker/talk-slug --skip-tests
```

**Expected output:** Same as regular migration but skips test execution

**Duration:** 30-60 seconds per talk (vs 1-3 minutes with tests)

**Trade-off:** Speed vs validation - run `bundle exec rake test:migration` afterward

**Warning:** May miss content issues that tests would catch

## Configuration Files

### _config.yml

**Purpose:** Main Jekyll configuration and speaker profile.

**Key sections:**
- `title`: Site title (appears in browser tab and feeds)
- `url`: Production URL (e.g., `https://username.github.io`)
- `baseurl`: Subdirectory if not at root (e.g., `/shownotes`)
- `speaker`: Speaker profile (name, bio, social links, photo)
- `collections`: Defines `_talks` collection with `output: true`

**Common modifications:**
- Update speaker profile when setting up
- Change `url` and `baseurl` for deployment
- Add custom Jekyll settings

**Validation:**
```bash
bundle exec jekyll build
```
If config is invalid, build will fail with error message.

**Important:** Changes require server restart when using `jekyll serve`

### _config_test.yml

**Purpose:** Test environment configuration - overrides `_config.yml` for testing.

**Key differences:**
- Uses test-specific URLs and paths
- Outputs to `_test_site/` instead of `_site/`
- May disable certain plugins for faster builds

**When used:** Automatically by test suite, rarely modified manually

**Validation:** Run test suite to verify test configuration

### Gemfile

**Purpose:** Ruby dependencies specification.

**Format:**
```ruby
source 'https://rubygems.org'

gem 'jekyll', '~> 4.3'
gem 'jekyll-feed'
# ... more gems
```

**Common modifications:**
- Adding new Jekyll plugins
- Updating gem versions
- Adding development tools

**After changes:** Run `bundle install` to update dependencies

**Lock file:** `Gemfile.lock` tracks exact versions, commit both files

### Rakefile

**Purpose:** Test and build task definitions.

**Available tasks:**
```bash
rake -T  # List all tasks
```

**Common tasks:**
- `rake test` - Run all tests
- `rake test:unit` - Run unit tests
- `rake test:integration` - Run integration tests
- `rake test:e2e` - Run E2E tests
- `rake test:migration` - Run migration tests
- `rake quick` - Run quick tests

**Customization:** Add custom tasks for project-specific automation

## Build System

### Rake

**Purpose:** Task automation and test orchestration.

**Usage:** `bundle exec rake <task>`

**Task definition:** See `Rakefile` for available tasks

**Custom tasks:** Add to `Rakefile` using Rake DSL

### Jekyll

**Build process:**
1. Reads `_config.yml` configuration
2. Processes collections (`_talks/`)
3. Applies layouts from `_layouts/`
4. Renders Liquid templates
5. Converts Markdown to HTML with Kramdown
6. Applies syntax highlighting with Rouge
7. Generates feeds, sitemaps, SEO tags
8. Outputs static files to `_site/`

**Incremental builds:** Jekyll caches processed files in `.jekyll-cache/` for faster rebuilds

**Clean build:** Delete `.jekyll-cache/` and `_site/` to force full rebuild

### Kramdown

**Purpose:** Markdown processing with GitHub-flavored markdown support.

**Features:**
- GFM tables, task lists, strikethrough
- Syntax highlighting for code blocks
- Automatic heading IDs for anchors
- Smart quotes and typography

**Configuration:** Set in `_config.yml` under `markdown:` and `kramdown:`

### Bundler

**Purpose:** Gem management and dependency resolution.

**Lock file:** `Gemfile.lock` ensures consistent versions across environments

**Update gems:**
```bash
bundle update  # Update all gems
bundle update jekyll  # Update specific gem
```

**Check outdated:**
```bash
bundle outdated
```

**Expected output:** List of gems with newer versions available, or "Bundle up to date!" if all current

## Security

### Input Validation

**XSS Protection:**
- HTML escaping in renderers via `CGI.escapeHTML()`
- Liquid templates auto-escape by default
- Manual escaping for user-generated content

**Implementation:** See `lib/talk_renderer.rb` for escaping patterns

**Testing:** XSS tests in `test/impl/unit/` verify escaping

### YAML Parsing

**Safe parsing:**
```ruby
YAML.safe_load(content, permitted_classes: [Date, Time])
```

**Why:** Prevents arbitrary code execution from malicious YAML

**Usage:** All YAML parsing in migration and rendering uses `safe_load`

**Permitted classes:** Only Date and Time allowed beyond basic types

### URL Validation

**External resources:**
- Validate URLs before embedding
- Check for valid schemes (http, https)
- Sanitize before rendering

**Implementation:** URL validation in migration script and renderers

**Purpose:** Prevent injection of malicious URLs

### Credentials Management

**Service account:**
- `Google API.json` contains service account credentials
- Required for Google Drive and Slides API access
- Never commit to version control

**Storage:**
- Keep in project root (git-ignored)
- Restrict file permissions: `chmod 600 Google API.json`
- Rotate credentials periodically

**`.gitignore` patterns:**
```
Google API.json
*.json  # Catches credential files
```

**Setup:** See [Migration Workflow](product.md#migration-workflow) for credential creation

### External Services

**Google API Authentication:**
- Service account authentication (not OAuth)
- Scoped permissions (Drive, Slides only)
- No user interaction required

**Rate limiting:**
- Google APIs have rate limits
- Migration script includes delays between requests
- Retry logic for transient failures

**Error handling:**
- Graceful degradation on API failures
- Clear error messages for authentication issues
- Validation of API responses

## Performance

### Build Performance

**Fast build options:**

1. **Incremental builds** (default with `jekyll serve`):
   - Only rebuilds changed files
   - Uses `.jekyll-cache/` for caching
   - 1-2 second rebuilds vs 10-30 second full builds

2. **Disable plugins** (test config):
   - Test config disables non-essential plugins
   - Faster builds for testing
   - Trade-off: Missing some production features

3. **Limit content** (development):
   - Use `limit:` in Liquid loops during development
   - Reduce number of talks processed
   - Restore for production builds

**Cache management:**
- Cache location: `.jekyll-cache/`
- Clear cache: `rm -rf .jekyll-cache/` if builds are stale
- Cache is git-ignored, safe to delete

**Build times:**
- Clean build: 10-30 seconds (depends on talk count)
- Incremental: 1-2 seconds
- Test build: 5-15 seconds

### Test Performance

**Quick test suite:**
```bash
bundle exec rake quick
```
- Duration: 30-60 seconds
- Coverage: Essential functionality only
- Use for: Rapid development feedback

**Full test suite:**
```bash
bundle exec rake test
```
- Duration: 2-5 minutes
- Coverage: Complete validation
- Use for: Pre-commit, pre-deployment

**Test categories by speed:**
1. Unit tests: Fastest (10-30 seconds)
2. Integration tests: Medium (30-60 seconds)
3. Migration tests: Medium (30-60 seconds)
4. E2E tests: Slowest (1-2 minutes)

**Optimization tips:**
- Run unit tests during development
- Run full suite before committing
- Use `TEST_SINGLE_TALK` for targeted testing
- Skip E2E tests if no UI changes

**Parallel testing:**
- Not currently implemented
- Could speed up test suite significantly
- Consider for future optimization

## Troubleshooting

### Dependency Issues

**Problem:** `bundle install` fails with gem conflicts

**Solution:**
```bash
# Delete lock file and retry
rm Gemfile.lock
bundle install

# If still fails, update bundler
gem install bundler
bundle install
```

**Problem:** Wrong Ruby version

**Solution:**
```bash
# Check current version
ruby -v

# Install correct version (using rbenv example)
rbenv install 3.4.0
rbenv local 3.4.0

# Verify
ruby -v
```

**Problem:** Native extension compilation fails (nokogiri)

**Solution:**
```bash
# macOS
brew install libxml2 libxslt
bundle config build.nokogiri --use-system-libraries
bundle install

# Linux
sudo apt-get install libxml2-dev libxslt-dev
bundle install
```

**Problem:** Permission errors during install

**Solution:**
```bash
# Don't use sudo with bundler
# Instead, configure bundler to install locally
bundle config set --local path 'vendor/bundle'
bundle install
```

### Build Issues

**Problem:** Jekyll build fails with template error

**Solution:**
1. Check error message for file and line number
2. Verify Liquid syntax in templates
3. Check for undefined variables
4. Validate YAML frontmatter

**Problem:** "Liquid Exception: undefined method"

**Solution:**
- Check that all referenced variables exist
- Verify plugin is loaded
- Check for typos in variable names

**Problem:** Styles not loading in built site

**Solution:**
1. Verify `url` and `baseurl` in `_config.yml`
2. Check that `baseurl` matches deployment path
3. Rebuild site after config changes
4. Clear browser cache

**Problem:** Build is very slow

**Solution:**
1. Check for large files in `assets/`
2. Clear `.jekyll-cache/`: `rm -rf .jekyll-cache/`
3. Use incremental builds: `jekyll serve --incremental`
4. Limit content during development

**Problem:** "Could not find gem" error

**Solution:**
```bash
bundle install
bundle exec jekyll build
```
Always use `bundle exec` to ensure correct gem versions.

### Migration Issues

**Problem:** Authentication fails with Google APIs

**Solution:**
1. Verify `Google API.json` exists in project root
2. Check that Drive and Slides APIs are enabled in Google Cloud Console
3. Verify service account has correct permissions
4. Check for typos in API key file
5. Regenerate credentials if corrupted

**Problem:** Slides upload fails

**Solution:**
1. Check service account has Drive access
2. Verify API quotas not exceeded
3. Check network connectivity
4. Try with `--skip-tests` to isolate issue
5. Check Google Cloud Console for API errors

**Problem:** Thumbnail download fails

**Solution:**
1. Notist may block automated downloads
2. Download thumbnail manually from Notist
3. Save as `{talk-slug}-thumbnail.png` in `assets/images/thumbnails/`
4. Fallback: `placeholder-thumbnail.svg` will be used

**Problem:** Migration creates malformed markdown

**Solution:**
1. Check Notist content for special characters
2. Review generated markdown file
3. Edit manually to fix formatting
4. Report issue if consistent problem

**Problem:** Tests fail after migration

**Solution:**
1. Review test output for specific failures
2. Check content validation errors
3. Verify frontmatter format
4. Ensure all required fields present
5. Run `TEST_SINGLE_TALK=slug bundle exec ruby test/migration/migration_test.rb` for details

**Problem:** Migration is very slow

**Solution:**
1. Use `--skip-tests` flag for faster migration
2. Run tests separately: `bundle exec rake test:migration`
3. Check network speed (downloads slides and thumbnails)
4. Migrate one talk at a time if issues persist

### Test Issues

**Problem:** Tests fail with "cannot load such file"

**Solution:**
```bash
bundle install
bundle exec rake test
```
Ensure all dependencies installed and using `bundle exec`.

**Problem:** E2E tests fail with browser driver error

**Solution:**
```bash
# Install Chrome/Chromium
# macOS
brew install --cask google-chrome

# Linux
sudo apt-get install chromium-browser

# Update selenium-webdriver
bundle update selenium-webdriver
```

**Problem:** Tests fail with "No such file or directory"

**Solution:**
1. Check that test fixtures exist
2. Verify test site is built: `bundle exec jekyll build --config _config_test.yml`
3. Check file paths in test code
4. Ensure working directory is project root

**Problem:** Tests pass locally but fail in CI

**Solution:**
1. Check Ruby version matches CI environment
2. Verify all dependencies in Gemfile
3. Check for environment-specific paths
4. Review CI logs for specific errors

**Problem:** Specific test fails intermittently

**Solution:**
1. Check for timing issues in E2E tests
2. Add waits or retries for flaky tests
3. Verify test isolation (no shared state)
4. Check for race conditions

**Problem:** Test suite hangs

**Solution:**
1. Check for infinite loops in code
2. Verify no blocking I/O without timeouts
3. Kill process and run specific test category
4. Check for deadlocks in concurrent code
