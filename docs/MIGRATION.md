# Migration Guide

Complete guide for migrating conference talks from Notist to your Jekyll-based show notes platform.

## Overview

The migration process automatically extracts content from Notist talks and creates Jekyll-compatible pages with all resources, thumbnails, and metadata properly configured.

## Prerequisites

Before migrating talks, ensure you have:

1. **Jekyll site configured** - See [Setup Guide](SETUP.md)
2. **Google Drive API setup** - Required for slide hosting
3. **Internet connection** - For downloading content and thumbnails

## Quick Migration

### Single Talk Migration

```bash
# Basic migration
ruby migrate_talk.rb https://noti.st/yourname/your-talk

# With verbose output
ruby migrate_talk.rb https://noti.st/yourname/your-talk --verbose

# Migration with testing
ruby migrate_talk.rb https://noti.st/yourname/your-talk --test
```

### What Happens During Migration

1. **Content Extraction**
   - Fetches talk metadata from Notist
   - Extracts title, description, and resources
   - Downloads thumbnail from og:image
   - Identifies slides and video URLs

2. **File Processing**
   - Downloads PDF slides (if available)
   - Uploads slides to Google Drive
   - Creates local thumbnail copy
   - Generates Jekyll markdown file

3. **Validation**
   - Tests all URLs for accessibility
   - Verifies Google Drive permissions
   - Validates generated content structure
   - Runs quality checks

## Batch Migration

### Multiple Talks

```bash
# Create a list of URLs
echo "https://noti.st/yourname/talk1" > talks_to_migrate.txt
echo "https://noti.st/yourname/talk2" >> talks_to_migrate.txt
echo "https://noti.st/yourname/talk3" >> talks_to_migrate.txt

# Migrate all talks
while read url; do
  ruby migrate_talk.rb "$url"
  sleep 2  # Be respectful to Notist servers
done < talks_to_migrate.txt
```

### From Speaker Profile

The migration script supports speaker mode for bulk migration:

```bash
# Migrate all talks from a speaker profile
ruby migrate_talk.rb --speaker https://noti.st/yourname
```

This will automatically discover and migrate all talks from the speaker's profile.

## Migration Process Details

### Content Mapping

| Notist Field | Jekyll Output | Notes |
|--------------|---------------|-------|
| Talk Title | `title:` frontmatter | Cleaned of HTML |
| Description | Content body | Converted to Markdown |
| Slides URL | `slideshare_url:` | Also uploaded to Google Drive |
| Video URL | `video_url:` | YouTube/Vimeo links preserved |
| Event Name | `conference:` | Extracted from page |
| Event Date | `date:` | ISO format (YYYY-MM-DD) |
| og:image | Local thumbnail | Downloaded to assets/images/thumbnails/ |

### File Structure

Migration creates:

```text
_talks/
└── YYYY-MM-DD-conference-talk-title.md    # Main talk file

assets/images/thumbnails/
└── talk-title-thumbnail.png               # Local thumbnail

pdfs/
└── YYYY-MM-DD-conference-talk-title.pdf   # Slides (if available)
```

### Generated Content Example

```markdown
---
layout: talk
title: "Your Talk Title"
date: 2024-06-12
conference: "Conference Name"
slideshare_url: "https://docs.google.com/presentation/d/..."
video_url: "https://www.youtube.com/watch?v=..."
thumbnail_url: "/assets/images/thumbnails/talk-title-thumbnail.png"
---

# Your Talk Title

**Conference:** Conference Name  
**Date:** June 12, 2024  
**Slides:** [View Slides](https://docs.google.com/presentation/d/...)  
**Video:** [Watch Video](https://www.youtube.com/watch?v=...)  

## Abstract

Your talk description extracted from Notist...

## Resources

- [Resource 1](https://example.com)
- [Resource 2](https://github.com/yourname/repo)
```

## Troubleshooting

### Common Issues

#### Migration Fails with "Content not found"

```bash
# Check if URL is accessible
curl -I "https://noti.st/yourname/your-talk"

# Verify URL format
# Correct: https://noti.st/speaker/talk-slug
# Incorrect: https://noti.st/speaker/talk-slug/
```

#### Google Drive Upload Fails

```bash
# Verify API credentials
ls -la "Google API.json"

# Test Google Drive connection
ruby test/external/google_drive_integration_test.rb

# Check quota limits
# Google Drive API has daily upload limits
```

#### Thumbnail Download Fails

```bash
# Check og:image URL manually
curl -I "$(ruby -e "require 'nokogiri'; require 'open-uri'; puts Nokogiri::HTML(URI.open('YOUR_NOTIST_URL')).at('meta[property=\"og:image\"]')['content']")"

# Verify image format
# Must be PNG, JPG, or WebP
```

#### Generated Content Issues

```bash
# Validate generated markdown
bundle exec jekyll build

# Check for YAML errors
ruby -c _talks/your-generated-file.md

# Run content validation
bundle exec ruby test/migration/migration_test.rb
```

### Manual Fixes

#### Fix Missing Conference Name

```yaml
# In generated file frontmatter
conference: "Add Conference Name Here"
```

#### Fix Date Format

```yaml
# Ensure ISO format
date: 2024-06-12  # YYYY-MM-DD
```

#### Fix Resource URLs

```markdown
## Resources

- [Fixed Resource Title](https://corrected-url.com)
```

## Advanced Migration Options

### Command Line Options

The migration script supports several command-line options:

```bash
# Skip integration tests after migration (faster)
ruby migrate_talk.rb https://noti.st/yourname/talk --skip-tests

# Migrate all talks for a speaker
ruby migrate_talk.rb --speaker https://noti.st/yourname

# Show help and all available options
ruby migrate_talk.rb --help

# Show version information
ruby migrate_talk.rb --version
```

### Speaker Mode vs Single Talk Mode

**Single Talk Mode** (default):
```bash
ruby migrate_talk.rb https://noti.st/yourname/individual-talk
```

**Speaker Mode** (bulk migration):
```bash
ruby migrate_talk.rb --speaker https://noti.st/yourname
```

### Migration Behavior Control

The migration script automatically:
- Checks if talks already exist (by source URL)
- Downloads thumbnails from Notist og:image  
- Uploads slides to Google Drive
- Runs validation tests (unless `--skip-tests`)
- Rebuilds Jekyll site

You can modify this behavior by:
- Using `--skip-tests` for faster migration
- Using `--speaker` for bulk processing
- Manually editing generated files after migration

## Post-Migration

### Verification Checklist

- [ ] Generated file exists in `_talks/`
- [ ] Thumbnail appears in `assets/images/thumbnails/`
- [ ] Jekyll builds without errors
- [ ] Talk page displays correctly
- [ ] All links are accessible
- [ ] Google Drive slides are public
- [ ] Mobile layout works

### Testing Migration

```bash
# Test specific migrated talk
TEST_SINGLE_TALK=your-talk-slug bundle exec ruby test/migration/migration_test.rb

# Run full migration test suite
bundle exec ruby test/run_tests.rb --category migration

# Validate site build
bundle exec jekyll build
bundle exec jekyll serve
```

### Manual Improvements

After migration, you may want to:

1. **Enhance descriptions** - Add more context or details
2. **Organize resources** - Group by type or importance  
3. **Add speaker notes** - Include additional insights
4. **Update links** - Replace any broken or outdated URLs
5. **Optimize thumbnails** - Crop or enhance if needed

## Migration Scripts

The migration functionality is built into the main script:

```bash
# Main migration script with all functionality
ruby migrate_talk.rb [options] <url>
```

Available options:
- `--speaker` - Migrate all talks from speaker profile
- `--skip-tests` - Skip validation tests after migration
- `--help` - Show detailed usage information
- `--version` - Show version information

For additional utilities, see the `utils/` directory which contains:
- `full_cleanup.rb` - Cleanup utility for development
- `utils/migration/migrate_talk.rb` - Alternative migration implementation

## Best Practices

### Before Migration

1. **Test with one talk first** - Verify your setup works
2. **Backup existing content** - In case something goes wrong
3. **Check API limits** - Google Drive has daily quotas
4. **Verify URLs** - Make sure Notist URLs are accessible

### During Migration

1. **Be respectful** - Add delays between requests
2. **Monitor progress** - Use verbose mode for large batches
3. **Check errors** - Don't ignore failed migrations
4. **Test incrementally** - Build and test after each migration

### After Migration

1. **Review content** - Check generated files for accuracy
2. **Test functionality** - Verify all links and resources work
3. **Optimize performance** - Compress images if needed
4. **Update documentation** - Keep your talk list current

## Next Steps

- **[Usage Guide](USAGE.md)** - Learn about manual content creation
- **[Advanced Features](ADVANCED.md)** - Customize your platform
- **[Testing](TESTING.md)** - Understand the test suite
