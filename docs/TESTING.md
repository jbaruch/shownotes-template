# Test Documentation

## Overview

Comprehensive testing documentation for the shownotes project, covering test scenarios, coverage analysis, and validation results.

## Test Organization

### Test Structure

```text
test/
├── run_tests.rb                    # Main unified test runner
├── migration/                      # Migration validation tests
├── external/                       # External API and dependency tests
├── tools/                          # Build tool and parser tests
└── impl/                           # Implementation tests
    ├── unit/                       # Fast unit tests (20 files)
    ├── integration/                # Integration tests (6 files)
    ├── e2e/                        # End-to-end tests (2 files)
    └── performance/                # Performance tests (1 file)
```

### Running Tests

```bash
# Run all tests
bundle exec ruby test/run_tests.rb

# Run by category
bundle exec ruby test/run_tests.rb --category unit
bundle exec ruby test/run_tests.rb --category migration
bundle exec ruby test/run_tests.rb --category external
```

## Migration Test Scenarios

### Overview

Test scenarios specifically for **per-page migration validation** from noti.st to Jekyll. This focuses on content migration quality and per-page functionality, not infrastructure setup.

### Test Categories

#### Test Suite 1: Content Migration Accuracy

**Test 1.1: Complete Resource Migration**

- **Objective**: Verify ALL resources from source are migrated
- **Method**: Dynamic source comparison against noti.st original
- **Expected**: Source resource count = Migrated resource count
- **Validation**: Count resources excluding slides/video (they're separate entities)

**Test 1.2: Resource Type Detection**

- **Objective**: Correctly categorize resources (slides, video, links, code)
- **Method**: Parse content and validate resource types
- **Expected**: Each resource properly identified and formatted
- **Validation**: Type-specific formatting and accessibility

**Test 1.3: Video Detection Accuracy**

- **Objective**: Detect video presence and validate accessibility
- **Method**: Check source for video, validate YouTube/Vimeo URLs
- **Expected**: Video URLs work and follow redirects properly
- **Validation**: HTTP 200 response after following redirects

#### Test Suite 2: Content Quality Assurance

**Test 2.1: Title Extraction**

- **Objective**: Extract accurate talk titles from source
- **Method**: Parse source page title, clean formatting
- **Expected**: Title matches source exactly
- **Validation**: No HTML entities, proper capitalization

**Test 2.2: Metadata Validation**

- **Objective**: Ensure all required metadata is present
- **Method**: Validate conference, date, slides, video fields
- **Expected**: All fields populated with valid data
- **Validation**: Date format, URL validity

**Test 2.3: Content Formatting**

- **Objective**: Ensure clean markdown format (not YAML monstrosity)
- **Method**: Parse generated files for format compliance
- **Expected**: Minimal YAML frontmatter + clean markdown body
- **Validation**: No liquid syntax in frontmatter, proper markdown structure

#### Test Suite 3: External Dependencies

**Test 3.1: URL Accessibility**

- **Objective**: Verify all external links are accessible
- **Method**: HTTP requests to validate URL responses
- **Expected**: 200 OK responses for all links
- **Validation**: Handle redirects, timeout protection

**Test 3.2: Google Drive Integration**

- **Objective**: Validate slides uploaded to Google Drive
- **Method**: Test Google Drive URLs and permissions
- **Expected**: Slides accessible via public sharing link
- **Validation**: PDF format, proper sharing permissions

**Test 3.3: Video Embedding**

- **Objective**: Ensure video embeds work properly
- **Method**: Validate YouTube/Vimeo embed codes
- **Expected**: Videos playable and properly embedded
- **Validation**: No privacy/cookie consent issues

## Test Coverage Analysis

### Requirements to Test Mapping

#### REQ-1.1.1: Talk Information Display

- **Test Scenarios**: Core information display validation
- **Gherkin**: "Talk page displays core information correctly"
- **Coverage**: Required

#### REQ-1.1.2: Resource Management

- **Test Scenarios**: Resource display and error handling
- **Gherkin**: "Talk page displays resources correctly" + "Talk page handles missing resources gracefully"
- **Coverage**: Required

#### REQ-1.1.3: Mobile Responsiveness

- **Test Scenarios**: Cross-device compatibility
- **Gherkin**: "Talk page is mobile responsive"
- **Coverage**: Required

#### REQ-1.1.4: Security

- **Test Scenarios**: Input validation and XSS prevention
- **Gherkin**: "Talk page handles user input securely"
- **Coverage**: Required

#### REQ-1.1.5: Performance

- **Test Scenarios**: Load time and optimization
- **Gherkin**: "Talk page loads quickly"
- **Coverage**: Required

### Test Implementation Guidelines

| Test Category | Focus Areas | Implementation Status |
|---------------|-------------|----------------------|
| **Content Migration Accuracy** | Resource extraction, validation | Required |
| **Content Quality Assurance** | Metadata, formatting | Required |
| **External Dependencies** | URL validation, API integration | Required |
| **Security Validation** | Input sanitization, XSS prevention | Required |
| **Performance Testing** | Load times, optimization | Required |
| **Accessibility** | WCAG compliance, screen readers | Required |
| **Mobile Responsiveness** | Touch interfaces, viewport handling | Required |
| **Template Consistency** | Layout, formatting standards | Required |
| **Error Handling** | Graceful degradation | Required |
| **Jekyll Integration** | Build process, collections | Required |
| **Speaker Configuration** | Profile management | Required |

**Goal**: Comprehensive test coverage across all functional areas

## Test Validation Results

### Test Quality Guidelines

The test suite is designed to ensure migration quality and site functionality. All tests should provide consistent, reliable results without false positives or negatives.

### Infrastructure Requirements

All infrastructure tests should pass:

- Jekyll build compilation: No errors
- Server startup: Running locally
- Collections configuration: _talks collection working
- Template rendering: No liquid syntax errors
- CSS/JS assets: Loading properly
- Mobile responsiveness: Viewport meta tags working

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
