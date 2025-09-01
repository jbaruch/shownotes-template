# Migration Documentation

## Overview

This document consolidates all migration-related information for the shownotes project, covering the process of migrating conference talks from noti.st to Jekyll format.

## Migration Workflow

### Step-by-Step Process

#### 1. Extract Talk Metadata
From `https://noti.st/USERNAME/TALK_ID` (or custom domain):
- Talk title, conference, date, description
- Speaker information

#### 2. Extract PDF Slides
From noti.st presentation page:
- Find PDF download link: `https://on.notist.cloud/pdf/deck-*.pdf`
- Download the PDF file locally
- Upload to Google Drive (see Google Drive Setup section)
- Get shareable link: `https://drive.google.com/file/d/FILE_ID/view`

#### 3. Extract Video Links
- Look for embedded YouTube/Vimeo videos
- Get direct video URLs
- Test video accessibility

#### 4. Extract Resource Links
- Collect all reference links, code repositories, demos
- Validate link accessibility
- Categorize by type (documentation, tools, examples)

#### 5. Generate Jekyll Markdown
- Use `utils/migration/migrate_talk.rb` script
- Generate clean markdown format with minimal frontmatter
- Include source_url for validation

## Google Drive Setup

### Prerequisites
Before running the migration script, you need to set up Google Drive access:

#### 1. Create Google Service Account
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google Drive API
4. Create a Service Account
5. Download the JSON credentials file

#### 2. Configure Credentials
1. Save the JSON file as `Google API.json` in the project root
2. **Important**: Add `Google API.json` to `.gitignore` to keep credentials secure
3. Never commit API credentials to version control

#### 3. Set Up Shared Drive
1. Create a Google Drive folder for PDF uploads
2. Share the folder with the service account email (found in the JSON file)
3. Give the service account "Editor" permissions
4. Note the folder ID from the URL for use in the migration script

### Security Notes
- The `Google API.json` file contains sensitive credentials
- This file should be git-ignored and never committed
- Each user will need their own service account and credentials
- Shared drive permissions are required for PDF uploads

### GitHub Actions Integration

For automated migration testing in CI/CD pipelines:

#### Setting Up Migration Test Credentials

1. **Go to your GitHub repository** → **Settings** → **Secrets and variables** → **Actions**
2. **Create a new repository secret**:
   - **Name**: `GOOGLE_API_CREDENTIALS_JSON`
   - **Value**: Copy the entire contents of your `Google API.json` file

#### Migration Testing in CI

- **External Tests**: Will use the GitHub secret for Google Drive API integration
- **Migration Tests**: Will validate that migrations detect incomplete data properly
- **Local vs CI**: 
  - Local development uses local `Google API.json` file
  - CI environment uses `GOOGLE_API_CREDENTIALS_JSON` secret
  - Tests skip gracefully when credentials unavailable

### CI/CD Integration

For automated migration testing in CI/CD pipelines:

#### Setting Up GitHub Secrets for Migration Tests

1. **Go to your GitHub repository** → **Settings** → **Secrets and variables** → **Actions**
2. **Create a new repository secret**:
   - **Name**: `GOOGLE_API_CREDENTIALS_JSON`
   - **Value**: Copy the entire contents of your `Google API.json` file

#### CI Migration Testing Behavior

- **External Tests**: Will use the GitHub secret for Google Drive API integration
- **Migration Tests**: Will validate that migrations detect incomplete data properly
- **Local vs CI**:
  - Local development uses local `Google API.json` file
  - CI environment uses `GOOGLE_API_CREDENTIALS_JSON` secret
  - Tests skip gracefully when credentials unavailable

This enables comprehensive migration validation in your CI pipeline while keeping credentials secure.

## Migration Scripts

### Enhanced Migration Tool v2.0

The migration process is automated through an enhanced script that supports two migration modes:

#### Single Talk Migration

For migrating individual talks:

```bash
bundle exec ruby migrate_talk.rb <talk_url>
```

**Example:**
```bash
bundle exec ruby migrate_talk.rb https://speaking.jbaru.ch/PjlHKD/robocoders-judgment-day-ai-ides-face-off
```

**Process:**
1. Fetches and parses the individual talk page
2. Extracts metadata (title, conference, date, speaker)
3. Downloads and uploads PDF slides to Google Drive
4. Finds video URLs (YouTube/Vimeo)
5. Extracts all resource links
6. Validates resource sources (no Notist dependencies)
7. Generates Jekyll markdown file
8. **Automatically runs migration tests** to validate completeness
9. Reports success/failure with actionable feedback

#### Bulk Speaker Migration

For migrating all talks from a speaker's profile:

```bash
bundle exec ruby migrate_talk.rb --speaker <speaker_profile_url>
```

**Example:**
```bash
bundle exec ruby migrate_talk.rb --speaker https://speaking.jbaru.ch
```

**Process:**
1. **Discovery**: Automatically finds all talk URLs on the speaker's profile page
2. **Batch Migration**: Migrates each talk sequentially using single talk process
3. **Progress Tracking**: Shows real-time progress with detailed status
4. **Error Handling**: Continues even if individual talks fail
5. **Comprehensive Testing**: Runs migration tests after all migrations complete
6. **Summary Report**: Provides detailed success/failure analysis with recommendations

#### Migration Script Features

**🧪 Automatic Test Integration:**
- Runs `bundle exec rake test:migration` after each migration
- Validates migration completeness immediately
- Provides feedback on incomplete migrations
- Same tests that run in CI pipeline

**📊 Enhanced Reporting:**
- Real-time progress for bulk migrations
- Success rate tracking and analysis
- Clear error messages with actionable steps
- Recommendations for manual review

**🔧 Robust Error Handling:**
- Graceful failure handling for network issues
- Continues bulk migration even if individual talks fail
- Detailed error logging for debugging
- Recovery guidance for common issues

**CLI Help & Versioning:**
```bash
# Get detailed help
bundle exec ruby migrate_talk.rb --help

# Check version and capabilities
bundle exec ruby migrate_talk.rb --version
```

#### Migration Workflow

**For New Migrations:**
1. Set up Google Drive credentials (see Google Drive Setup section)
2. Choose migration mode (single talk vs. bulk speaker)
3. Run migration script with appropriate URL
4. Review generated files in `_talks/` directory
5. Check migration test results for completeness validation
6. Commit generated files to repository

**Quality Assurance:**
- Migration tests run automatically after each migration
- Tests validate resource count matches source
- Tests check for proper resource types and sources
- CI pipeline runs same tests for continuous validation

## Migration Quality Validation

### Overview
- **Migration Script**: `utils/migration/migrate_talk.rb` - Single authoritative migration script
- **Test Suite**: `test/migration/migration_test.rb` - Comprehensive validation
- **Format**: Clean markdown with minimal YAML frontmatter

### Verification Checklist

#### Structure Validation
- ✅ **Build**: No errors in Jekyll compilation
- ✅ **Server**: Local preview available at http://127.0.0.1:4000/
- ✅ **Collections**: _talks collection properly configured

#### Sample Migration Test
- ✅ **File Created**: Clean markdown format with minimal frontmatter
- ✅ **Front Matter**: All required fields present including source_url
- ✅ **Resources**: Properly structured and counted (excluding slides/video)
- ✅ **Content**: Proper markdown with sections

## Test Coverage

### Migration Test Suite
The migration test suite (`test/migration/migration_test.rb`) provides comprehensive validation:

| Test Category | Coverage | Status |
|---------------|----------|---------|
| **Content Migration Accuracy** | Resource count validation, source comparison | ✅ Complete |
| **Resource Type Detection** | Slides, video, links, code repositories | ✅ Complete |
| **URL Validation** | Video accessibility, redirect handling | ✅ Complete |
| **Format Consistency** | Clean markdown, no YAML monstrosity | ✅ Complete |
| **External Dependencies** | Google Drive slides, YouTube videos | ✅ Complete |

## Known Issues

### Migration Script Limitations
- Requires manual intervention for complex resource extraction
- Google Drive API quota limitations for large batches
- Network dependencies for source validation

## Migration Commands

```bash
# Migrate a single talk
cd utils/migration
ruby migrate_talk.rb https://noti.st/USERNAME/TALK_ID

# Clean up Google Drive files (for re-migration)
cd utils/google_drive
ruby cleanup_google_drive.rb

# Validate migration
bundle exec ruby test/migration/migration_test.rb

# Run all migration tests
bundle exec ruby test/run_tests.rb --category migration
```

## File Format

### Clean Markdown Format (Current Standard)
```markdown
---
layout: talk
source_url: https://noti.st/USERNAME/TALK_ID
---

# Talk Title

**Conference:** Conference Name
**Date:** YYYY-MM-DD
**Slides:** [View Slides](https://drive.google.com/file/d/FILE_ID/view)
**Video:** [Watch Video](https://youtube.com/watch?v=VIDEO_ID)

Talk description and content...

## Resources

- [Resource Name](url) - Description
```

This format ensures:
- Minimal YAML frontmatter (layout + source_url only)
- Clean, readable markdown content
- Consistent metadata formatting
- Source URL tracking for validation
