# Conference Talk Show Notes

A Jekyll-based platform for creating mobile-optimized conference talk pages with automatic resource management and QR code accessibility.

## ⚡ Quick Start (No Installation Required)

Perfect for speakers who want a simple, mobile-friendly page for their talks.

### 1. Fork and Clean
```bash
# Fork this repository on GitHub, then:
git clone https://github.com/YOUR-USERNAME/shownotes.git
cd shownotes

# Remove example talks
rm _talks/*.md
```

### 2. Configure Your Speaker Profile
Edit `_config.yml`:
```yaml
speaker:
  name: "Your Full Name"
  bio: "Your professional bio..."
  social:
    linkedin: "your-username"      
    github: "your-username"       
    x: "your-username"            

# Site settings
title: "Your Conference Talks"
url: "https://YOUR-USERNAME.github.io"
baseurl: "/shownotes"  # Or your repo name
```

### 3. Add Your First Talk
Create `_talks/2024-06-12-conference-talk-title.md`:
```markdown
---
layout: talk
---

# Talk Title Here

**Conference:** DevConf 2024  
**Date:** 2024-06-12  
**Slides:** [View Slides](https://your-slides-url)  
**Video:** [Watch Video](https://your-video-url)  

A presentation at DevConf 2024 in June 2024 by {{ site.speaker.name }}

## Abstract

Your talk description here. Explain what attendees will learn
and why it matters for their work.

## Resources

- [Main Resource](https://example.com)
- [Code Repository](https://github.com/yourname/repo)
- [Documentation](https://docs.example.com)
```

### 4. Add a Thumbnail (Optional)
Save an image with 4:3 aspect ratio (any resolution) as:
```
assets/images/thumbnails/2024-06-12-conference-talk-title-thumbnail.png
```
*The platform automatically resizes images to 400x300 while maintaining aspect ratio.*

### 5. Deploy
- Push to GitHub
- Enable GitHub Pages in repository Settings
- Your site will be live at `https://YOUR-USERNAME.github.io/shownotes`

**That's it!** 🎉 Your talk page is live and mobile-optimized.

---

## 🚀 Next Level: Automated Migration

For speakers with multiple talks or those using Notist.

### Prerequisites
- Ruby 3.4+ installed
- Google Drive API setup (see [Migration Guide](docs/MIGRATION.md#google-drive-api-setup))

### Migration Setup
```bash
# Install dependencies
bundle install

# Set up Google Drive API credentials
# Follow detailed instructions in docs/MIGRATION.md

# Migrate all talks from your Notist profile
ruby migrate_talk.rb --speaker https://noti.st/yourname

# Or migrate a single talk
ruby migrate_talk.rb https://noti.st/yourname/your-talk
```

### What Migration Does
- ✅ Extracts all content from Notist automatically
- ✅ Downloads and hosts slides on Google Drive
- ✅ Downloads thumbnails automatically  
- ✅ Generates properly formatted markdown
- ✅ Validates all resources work
- ✅ Rebuilds your site

---

## 📚 Advanced Features

For power users who want complete customization and automation.

### Local Development
```bash
# Full setup for advanced users
git clone https://github.com/jbaruch/shownotes.git
cd shownotes
bundle install
bundle exec jekyll serve
```

### Testing & Validation
```bash
# Run all tests
bundle exec ruby test/run_tests.rb

# Test single talk during development
TEST_SINGLE_TALK=your-talk-name bundle exec ruby test/migration/migration_test.rb
```

### Available Guides
- **[Advanced Customization](docs/ADVANCED.md)** - Themes, layouts, custom domains
- **[Development Setup](docs/DEVELOPMENT.md)** - Local development, testing, contributing
- **[Deployment Options](docs/ADVANCED.md#deployment)** - Netlify, Vercel, custom hosting
- **[Analytics Integration](docs/ADVANCED.md#analytics)** - Google Analytics, tracking setup

---

## ✨ Features

- **📱 Mobile-First Design** - Optimized for conference WiFi and mobile devices
- **🔗 QR Code Ready** - Perfect for sharing via slides or business cards
- **⚡ Zero Dependencies** - Works with GitHub Pages out of the box
- **🖼️ Automatic Thumbnails** - From your first slide or custom images
- **📋 Resource Management** - Organized links to slides, videos, code, docs
- **🎯 SEO Optimized** - Proper meta tags and structured data
- **⚡ Fast Loading** - Minimal, optimized static site
- **🔒 Secure & Accessible** - XSS protection and WCAG-compliant

## 🔧 Requirements

### Basic Usage (GitHub Pages)
- GitHub account
- Text editor

### Migration Features
- Ruby 3.4+
- Bundler
- Google Drive API access (optional, for slide hosting)

### Advanced Development
- Jekyll 4.4+
- Git
- Ruby development environment

## 💡 Examples

Live examples of talks using this platform:
- [DevOps Reframed](https://jbaru.ch/2024-11-07-devignition-2024-devops-reframed) - With video and slides
- [RoboCoders](https://jbaru.ch/2025-06-12-devoxx-poland-robocoders-judgment) - With resources and code

## 📚 Documentation

### Getting Started
- **[Setup Guide](docs/SETUP.md)** - Detailed installation and configuration
- **[Usage Guide](docs/USAGE.md)** - Creating and managing talk content

### Advanced Features  
- **[Migration Guide](docs/MIGRATION.md)** - Automated talk migration from Notist
- **[Advanced Features](docs/ADVANCED.md)** - Customization, deployment, analytics
- **[Development Guide](docs/DEVELOPMENT.md)** - Contributing and development
- **[Testing Guide](docs/TESTING.md)** - Running tests and validation

## 🆘 Support

- **Quick Questions**: Check [docs/](docs/) directory
- **Migration Issues**: See [Migration Guide](docs/MIGRATION.md)
- **Bug Reports**: Use GitHub Issues
- **Feature Requests**: Use GitHub Discussions

## 📄 License

[Apache 2.0](LICENSE)
