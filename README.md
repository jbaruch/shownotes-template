# Conference Talk Show Notes

A Jekyll-based platform for creating mobile-optimized conference talk pages with automatic resource management and QR code accessibility.

## Quick Start

```bash
# 1. Clone and install
git clone <repository-url>
cd shownotes
bundle install

# 2. Personalize (see Setup section)
# Edit _config.yml with your speaker information

# 3. Add your first talk
# Option A: Migrate from Notist (recommended)
ruby migrate_talk.rb https://noti.st/yourname/your-talk

# Option B: Create manually (see Usage section)
# Create file in _talks/ directory

# 4. Build and serve
bundle exec jekyll build
bundle exec jekyll serve
```

## Features

- **📱 Mobile-First**: Optimized for conference attendees accessing via mobile devices
- **🔗 QR Code Ready**: Quick verification during presentations  
- **📋 Smart Resources**: Organized display of slides, videos, code, and links
- **⚡ Performance Optimized**: Fast loading on conference networks
- **🔒 Secure**: XSS protection and input validation
- **🎯 Accessible**: WCAG-compliant screen reader and keyboard navigation
- **🖼️ Automatic Thumbnails**: Downloaded from Notist or manually added
- **🧪 Comprehensive Testing**: Ensures quality and reliability

## Documentation

- **[Setup Guide](docs/SETUP.md)** - Installation, configuration, and personalization
- **[Usage Guide](docs/USAGE.md)** - Creating talks manually and managing content
- **[Migration Guide](docs/MIGRATION.md)** - Migrating talks from Notist
- **[Advanced Features](docs/ADVANCED.md)** - Customization and troubleshooting
- **[Development](docs/DEVELOPMENT.md)** - Contributing and development setup
- **[Testing](docs/TESTING.md)** - Running and understanding tests

## Requirements

- Ruby 3.4+
- Bundler
- Jekyll 4.4+
- Git

## Setup

### 1. Install Dependencies

```bash
bundle install
```

### 2. Configure Speaker Information

Edit `_config.yml`:

```yaml
speaker:
  name: "Your Full Name"
  display_name: ""                 # Optional: Override for display
  bio: "Your professional bio..."
  
  social:
    linkedin: "your-username"      
    x: "your-username"            
    github: "your-username"       
    mastodon: ""                  # Full URL
    bluesky: "your-handle"        
```

### 3. Update Site Settings

```yaml
url: "https://yourdomain.com"
title: "Your Conference Talks"
description: "Mobile-optimized conference talk resources"
```

## Usage

### From Notist (Recommended)

```bash
# One command migration with automatic testing
ruby migrate_talk.rb https://noti.st/yourname/your-talk

# This automatically:
# - Extracts content and metadata
# - Downloads and uploads slides to Google Drive
# - Downloads thumbnail from Notist
# - Runs validation tests
# - Rebuilds Jekyll site
```

### Manual Creation

Create `_talks/YYYY-MM-DD-conference-talk-title.md`:

```markdown
---
layout: talk
---

# Talk Title Here

**Conference:** Conference Name  
**Date:** 2024-06-12  
**Slides:** [View Slides](your-slides-url)  
**Video:** [Watch Video](your-video-url)  

## Abstract

Your talk description...

## Resources

- [Resource Title](https://example.com)
- [Code Repository](https://github.com/yourname/repo)
```

### Thumbnails

- **Notist talks**: Thumbnails automatically downloaded during migration
- **Manual talks**: Add `assets/images/thumbnails/{talk-slug}-thumbnail.png`
- **Missing thumbnails**: Automatically use placeholder

## Testing

```bash
# Run all tests
bundle exec ruby test/run_tests.rb

# Test single talk during development
TEST_SINGLE_TALK=your-talk-name bundle exec ruby test/migration/migration_test.rb

# Run migration tests (requires Google Drive API setup)
bundle exec ruby test/run_tests.rb -c migration
```

## Support

- **Issues**: Use GitHub Issues for bug reports and feature requests
- **Documentation**: Check the [docs/](docs/) directory for detailed guides
- **Testing**: Run the test suite to verify your setup

## License

[Apache 2.0](LICENCE)
