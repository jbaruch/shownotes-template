# Testing Guide

Simple guide for running tests and validating changes to the Conference Talk Show Notes platform.

## Quick Start

### Run All Tests

```bash
# Install dependencies first
bundle install

# Run the complete test suite
bundle exec ruby test/run_tests.rb
```

### Run Specific Test Categories

```bash
# Migration tests (verify talk migration works)
bundle exec ruby test/run_tests.rb --category migration

# Unit tests (fast core functionality tests)
bundle exec ruby test/run_tests.rb --category unit

# External tests (API connectivity)
bundle exec ruby test/run_tests.rb --category external

# Integration tests (full workflow)
bundle exec ruby test/run_tests.rb --category integration
```

## Test Organization

### Test Structure

```text
test/
├── run_tests.rb              # Main test runner - use this
├── migration/                # Tests for talk migration
│   ├── migration_test.rb     # Core migration validation
│   └── *_test.rb            # Additional migration tests
├── impl/                     # Implementation tests
│   ├── unit/                 # Fast unit tests
│   ├── integration/          # Integration tests  
│   ├── e2e/                  # End-to-end tests
│   └── performance/          # Performance tests
├── external/                 # External service tests
└── tools/                    # Build and utility tests
```

## Common Test Scenarios

### Testing Talk Migration

```bash
# Test migrating a specific talk
bundle exec ruby migrate_talk.rb "https://noti.st/speaker/talk-slug"

# Validate the migration worked
bundle exec ruby test/migration/migration_test.rb
```

### Testing Site Build

```bash
# Test Jekyll site builds correctly
bundle exec jekyll build

# Test site serves locally
bundle exec jekyll serve

# Run integration tests against local site
bundle exec ruby test/run_tests.rb --category integration
```

### Testing Thumbnails

```bash
# Verify thumbnail system works
bundle exec ruby test/impl/unit/thumbnail_test.rb

# Test thumbnail fallback behavior
bundle exec ruby test/impl/integration/thumbnail_integration_test.rb
```

## Troubleshooting Tests

### Test Failures

#### Migration Tests Fail

```bash
# Check if source URL is accessible
curl -I "https://noti.st/speaker/talk-slug"

# Verify Google Drive API setup
bundle exec ruby test/external/google_drive_integration_test.rb

# Run specific migration test
bundle exec ruby test/migration/migration_test.rb --verbose
```

#### Build Tests Fail

```bash
# Check Jekyll dependencies
bundle check

# Rebuild site cleanly
bundle exec jekyll clean
bundle exec jekyll build

# Check for syntax errors
bundle exec jekyll doctor
```

#### External Tests Fail

```bash
# Test network connectivity
ping google.com

# Check API credentials
ls -la "Google API.json"

# Test specific external service
bundle exec ruby test/external/notist_api_test.rb
```

### Common Issues

#### Bundler Problems

```bash
# Update Gemfile.lock
bundle update

# Clean bundle cache
bundle clean --force

# Reinstall gems
bundle install --redownload
```

#### Permission Issues

```bash
# Fix file permissions
chmod +x test/run_tests.rb
chmod +x migrate_talk.rb

# Check Google Drive API file
chmod 600 "Google API.json"
```

## Test Development

### Adding New Tests

Create tests in appropriate directory:

```ruby
# test/impl/unit/my_feature_test.rb
require_relative '../../../lib/my_feature'

class MyFeatureTest < Test::Unit::TestCase
  def test_basic_functionality
    feature = MyFeature.new
    assert_equal "expected", feature.process("input")
  end
end
```

Register in test runner:

```ruby
# test/run_tests.rb (add to appropriate category)
UNIT_TESTS = [
  # ... existing tests
  'test/impl/unit/my_feature_test.rb'
]
```

### Test Best Practices

- **Fast tests**: Unit tests should run quickly
- **Isolated tests**: Tests shouldn't depend on each other
- **Clear assertions**: Use descriptive assertion messages
- **Cleanup**: Clean up any created files or state

## Continuous Integration

Tests run automatically on:
- Pull requests
- Main branch commits
- Scheduled daily runs

View results in GitHub Actions or your CI platform.

## Next Steps

- Run tests locally before committing
- Add tests for new features
- Keep tests updated with code changes
- Monitor test performance and reliability

### Test Quality Metrics

#### Test Reliability Goals

- **False Positives**: 0 (no tests failing incorrectly)
- **False Negatives**: 0 (no tests passing when they should fail)
- **Test Stability**: Consistent results across runs
- **Environment Independence**: Tests work in all environments

#### Performance Targets

- **Migration Test Suite**: Under 10 seconds
- **Unit Test Suite**: Under 5 seconds
- **Integration Test Suite**: Under 15 seconds
- **Full Test Suite**: Under 30 seconds

## Test Contracts and Specifications

### Page Structure Contract

#### HTML Document Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta property="og:title" content="[Talk Title]">
  <meta property="og:description" content="[Talk Description]">
  <meta property="og:type" content="article">
  <!-- CSP and security headers -->
</head>
<body>
  <!-- Page content with proper semantic structure -->
</body>
</html>
```

#### Content Requirements

- **Title**: H1 heading with talk title
- **Metadata**: Conference, date, slides, video in consistent format
- **Description**: Talk description and content
- **Resources**: Organized list of related links
- **Speaker Info**: Avatar, name, social links

#### Responsive Design

- **Mobile First**: Optimized for mobile devices
- **Breakpoints**: 480px, 768px, 1024px, 1200px
- **Navigation**: Touch-friendly interface
- **Performance**: Fast loading on conference networks

### Jekyll Integration Contract

#### Collection Structure

- **Directory**: `_talks/`
- **File Format**: `YYYY-MM-DD-conference-talk-slug.md`
- **Front Matter**: Minimal YAML (layout + source_url)
- **Content**: Clean markdown with consistent metadata

#### Build Requirements

- **Jekyll Version**: 4.4.1+
- **Plugins**: Minimal plugin dependencies
- **Build Time**: Under 10 seconds for full site
- **Output**: Static HTML/CSS/JS files

## Maintenance and Updates

### Test Suite Maintenance

- **Regular Review**: Monthly review of test scenarios
- **New Feature Testing**: Add tests for new features before implementation
- **Regression Testing**: Run full suite before releases
- **Performance Monitoring**: Track test execution times

### Documentation Updates

- **Test Results**: Update after each test run
- **Coverage Analysis**: Review quarterly
- **Scenario Updates**: Add new scenarios as requirements evolve
- **Contract Updates**: Update contracts when APIs change
