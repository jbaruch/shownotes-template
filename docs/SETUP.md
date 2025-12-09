# Setup Guide

Complete installation and configuration guide for the Conference Talk Show Notes platform.

## Prerequisites

- **Ruby 3.4+** (check with `ruby --version`)
- **Git** (for version control)
- **Text editor** (VS Code, Vim, etc.)

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd shownotes
```

### 2. Install Ruby Dependencies

```bash
# Install bundler if not already installed
gem install bundler

# Install project dependencies
bundle install
```

### 3. Verify Installation

```bash
# Test that Jekyll works
bundle exec jekyll --version

# Should output: jekyll 4.4.1 (or similar)
```

## Configuration

### Speaker Information

Edit `_config.yml` to configure your speaker profile:

```yaml
speaker:
  name: "Your Full Name"
  display_name: ""                 # Optional: Different display name
  bio: "Your professional bio here..."
  avatar_url: ""                   # Optional: Custom avatar URL
  
  social:
    linkedin: "your-username"      # LinkedIn username only
    x: "your-username"            # X.com (Twitter) username
    github: "your-username"       # GitHub username
    mastodon: ""                  # Full Mastodon URL (e.g., https://mastodon.social/@username)
    bluesky: "your-handle"        # BlueSky handle (e.g., user.bsky.social)
```

### Site Settings

```yaml
# Basic site information
title: "Your Conference Talks"
description: "Mobile-optimized conference talk resources"
url: "https://yourdomain.com"     # Your deployed site URL
baseurl: ""                       # Subdirectory if needed (e.g., "/talks")

# Jekyll settings
permalink: /:title/
markdown: kramdown
highlighter: rouge
plugins:
  - jekyll-feed

# Collections
collections:
  talks:
    output: true
    permalink: /:name/
```

### Google Drive Integration (Optional)

Required only for **Notist migration** and **PDF hosting**:

#### 1. Create Google Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google Drive API
4. Go to "IAM & Admin" → "Service Accounts"
5. Create new service account with "Editor" role
6. Generate JSON key file

#### 2. Setup Credentials

```bash
# Save the JSON key file as:
cp path/to/your-service-account.json "Google API.json"

# Verify file is correctly named and in root directory
ls "Google API.json"
```

#### 3. Create Shared Drive

1. In Google Drive, create a new Shared Drive
2. Share it with your service account email (from the JSON file)
3. Give "Manager" permissions

#### 4. Configure Drive Settings

Add to `_config.yml`:

```yaml
google_drive:
  shared_drive_name: "Your Shared Drive Name"
  credentials_file: "Google API.json"
```

## First-Time Setup

### 1. Clear Sample Content (Optional)

If you want to start fresh:

```bash
# Backup existing talks
mkdir backup
mv _talks/*.md backup/ 2>/dev/null || true

# Or remove them entirely
rm _talks/*.md 2>/dev/null || true
```

### 2. Test Configuration

```bash
# Build the site
bundle exec jekyll build

# Start local development server
bundle exec jekyll serve

# Open http://localhost:4000 in your browser
```

### 3. Verify Speaker Profile

- Check that your name appears correctly
- Verify social links work
- Confirm bio displays properly

## Directory Structure

After setup, your directory should look like:

```text
shownotes/
├── _config.yml                 # Your configuration
├── "Google API.json"           # Google Drive credentials (if using migration)
├── _talks/                     # Your talk files
├── assets/images/thumbnails/   # Talk thumbnails
├── docs/                       # Documentation
│   └── templates/              # Template files
│       └── sample-talk.md      # Talk file template
├── test/                       # Test suite
└── README.md                   # Project overview
```

**Important Files**:
- `_config.yml`: Site and speaker configuration
- `_talks/`: Your conference talk markdown files
- `docs/templates/sample-talk.md`: Template for creating new talks
- `assets/images/thumbnails/`: Talk thumbnail images

## Environment Setup

### Development Environment

```bash
# Development server with auto-reload
bundle exec jekyll serve --livereload

# Development with drafts
bundle exec jekyll serve --drafts

# Custom port
bundle exec jekyll serve --port 4001
```

### Production Build

```bash
# Build for production
bundle exec jekyll build

# The _site/ directory contains the generated site
```

## Troubleshooting

### Common Issues

#### 1. Bundle Install Fails

```bash
# Update bundler
gem update bundler

# Clear cache and reinstall
bundle cache clean --force
bundle install
```

#### 2. Jekyll Version Conflicts

```bash
# Check Ruby version (should be 3.4+)
ruby --version

# Update gems
bundle update
```

#### 3. Permission Issues (macOS/Linux)

```bash
# Install gems in user directory
bundle config set --local path 'vendor/bundle'
bundle install
```

#### 4. Google Drive API Issues

```bash
# Verify JSON file format
cat "Google API.json" | head -5

# Should show: {"type": "service_account", ...

# Test API access
bundle exec ruby -e "require 'google-apis-drive_v3'; puts 'API accessible'"
```

### Testing Your Setup

```bash
# Run basic tests
bundle exec ruby test/run_tests.rb -c unit

# Test speaker configuration
bundle exec ruby test/impl/unit/speaker_config_test.rb

# Test Jekyll build
bundle exec ruby test/impl/integration/jekyll_build_test.rb

# Test markdown parser plugin
bundle exec ruby test/impl/unit/markdown_parser_test.rb
```

### Verifying Production Deployment

After deploying to production, verify everything works correctly:

```bash
# Run production health tests (requires deployed site)
bundle exec ruby test/impl/e2e/production_health_test.rb

# These tests verify:
# - Homepage loads correctly
# - Talk titles are properly extracted (not slugified)
# - Metadata displays correctly
# - Sample talk template doesn't appear on production
```

**Note**: Production health tests will skip automatically in CI environments. Run them manually after deployments to verify the live site.

## Next Steps

1. **Create your first talk**: See [Usage Guide](USAGE.md)
2. **Migrate from Notist**: See [Migration section in Usage Guide](USAGE.md#from-notist-recommended)  
3. **Customize the theme**: See [Advanced Features](ADVANCED.md)
4. **Deploy your site**: See [Advanced Features](ADVANCED.md#deployment)

## Getting Help

- **Configuration issues**: Check this guide and [Advanced Features](ADVANCED.md)
- **Migration problems**: See [Usage Guide](USAGE.md) and [Development Guide](DEVELOPMENT.md)  
- **Test failures**: See [Testing Guide](TESTING.md)
- **Bug reports**: Use GitHub Issues
