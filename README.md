# Conference Talk Show Notes Platform

A Jekyll-based static site generator for creating mobile-optimized conference talk pages with resource management and QR code accessibility.

## Features

- **Mobile-First Design**: Optimized for conference attendees accessing via mobile devices
- **QR Code Accessibility**: Quick verification during presentations
- **Resource Management**: Organized display of slides, code repositories, and reference links  
- **Performance Optimized**: Fast loading on conference networks
- **Security Focused**: XSS protection, input validation, and secure output rendering
- **Speaker Configuration**: Centralized speaker info with social media integration and avatar priority
- **Jekyll Compatible**: Seamless integration with Jekyll static site generation
- **Responsive Layout**: CSS Grid-based responsive design
- **Accessibility Compliant**: WCAG-compatible screen reader and keyboard navigation

## Requirements

- Ruby 3.4+
- Bundler
- Jekyll 4.4+
- Git

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd shownotes

# Install dependencies  
bundle install

# Build the site
bundle exec jekyll build

# Serve locally
bundle exec jekyll serve
```

## Testing

Comprehensive test suite covering all functionality:

```bash
# Run all tests
ruby test/test_runner.rb

# Run specific test files
bundle exec ruby test/impl/unit/[test_file].rb
bundle exec ruby test/impl/integration/[test_file].rb
```

**Current Test Results**: 191 tests, 1,291 assertions, 0 failures

## Project Structure

```
shownotes/
├── _config.yml                 # Jekyll configuration
├── _layouts/                   # Jekyll layout templates  
├── _talks/                     # Talk content collection
├── _plugins/                   # Jekyll plugins
│   └── markdown_parser.rb      # All-markdown format parser
├── assets/                     # CSS, JS, images
├── lib/                        # Core implementation
│   ├── talk_renderer.rb        # Full rendering engine (Jekyll + dependencies)
│   └── simple_talk_renderer.rb # Lightweight renderer (minimal dependencies)
├── migrate_talk.rb             # Notist migration (full-featured)
├── migrate_talk_simple.rb      # Notist migration (lightweight)
├── migrate_format.rb           # YAML→Markdown format converter
├── utils/                      # Development utilities
│   ├── cleanup_google_drive.rb # Google Drive cleanup tools
│   ├── delete_google_drive_file.rb
│   ├── force_delete_files.rb
│   └── test_real_site.rb       # Site testing utilities
├── test/                       # Comprehensive test suite
│   ├── visual_test_simple.rb   # Visual regression tests
│   ├── migration_test.rb       # Migration validation tests
│   └── impl/
│       ├── unit/               # Unit tests (11 files)
│       ├── integration/        # Integration tests
│       ├── performance/        # Performance tests  
│       └── e2e/                # End-to-end tests
├── docs/                       # Project documentation
└── Rakefile                    # Test automation
```

## Usage

### Configuration

#### Speaker Configuration

Configure speaker information in `_config.yml` as a single source of truth:

```yaml
# Speaker configuration (single source of truth)
speaker:
  name: "Your Name"                 # Required: Full name
  display_name: ""                  # Optional: Override for display (if empty, uses name)
  bio: "Your professional bio..."   # Required: Speaker biography
  avatar_url: ""                    # Optional: Custom avatar URL (fallback if no social media avatars)
  
  # Social media handles (all optional - leave empty to hide)
  social:
    linkedin: "username"            # LinkedIn username (generates profile link + avatar)
    x: "username"                   # X.com username (generates profile link + avatar)  
    github: "username"              # GitHub username (generates profile link + avatar)
    mastodon: "https://instance/@user" # Full Mastodon URL
    bluesky: "username"             # BlueSky username (generates profile link)
```

**Avatar Priority**: GitHub > LinkedIn > X.com > Custom avatar_url > Default

### Creating Talk Pages

1. Add talk files to `_talks/` directory:

```yaml
---
layout: talk
---

# Talk Title Here

**Conference:** Conference Name 2024  
**Date:** 2024-03-15  
**Slides:** [View Slides](https://slides.example.com)  
**Video:** [Watch Video](https://youtube.com/watch?v=example)  

Talk description and additional content in Markdown format.

## Resources

- [DevOps Tools For Java Developers](https://amzn.to/4io8r3I)
- [Liquid Software](https://amzn.to/3F9i5cb)
- [Related Article](https://example.com/article)
```

1. Build and deploy:

```bash
bundle exec jekyll build
```

### QR Code Integration

Generate QR codes pointing to talk URLs for conference presentations. Pages are optimized for quick mobile access during talks.

## Development

### Architecture

- **Static Site Generation**: Jekyll-compatible processing
- **Template Engine**: Liquid templates with custom renderers
- **Content Processing**: Markdown with YAML frontmatter
- **Styling**: CSS Grid responsive layouts
- **Security**: Input sanitization and XSS protection
- **Performance**: Optimized for conference network conditions

### Test-First Development

Built using strict test-first methodology:

1. Requirements analyzed and documented
2. Test scenarios created from requirements  
3. Comprehensive test suite implemented
4. Implementation built to satisfy tests
5. 100% test success achieved

### Contributing

1. Run tests to ensure everything works: `bundle exec rake test`
2. Make your changes
3. Add tests for new functionality
4. Ensure all tests pass: `bundle exec rake test`
5. Submit pull request

## Security

- **XSS Protection**: All user input properly escaped
- **Input Validation**: Comprehensive data validation  
- **Output Sanitization**: Safe HTML generation
- **Security Headers**: CSP, X-Frame-Options, etc.
- **URL Validation**: Prevents malicious link injection

## Performance

- **Mobile Optimized**: Fast loading on mobile devices
- **Resource Efficient**: Minimized payload sizes
- **CDN Ready**: Static files optimized for CDN delivery
- **Progressive Enhancement**: Core functionality without JavaScript

## Support

For issues, questions, or contributions, please see the project documentation in the `docs/` directory or create an issue in the repository.

## License

Licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.

---

**Built with test-first development** | **Mobile-first design** | **Jekyll-powered**
