# Conference Talk Show Notes Platform

A Jekyll-based static site generator for creating mobile-optimized conference talk pages with resource management and QR code accessibility.

## 🚀 Features

- **Mobile-First Design**: Optimized for conference attendees accessing via mobile devices
- **QR Code Accessibility**: Quick verification during presentations
- **Resource Management**: Organized display of slides, code repositories, and reference links  
- **Performance Optimized**: Fast loading on conference networks
- **Security Focused**: XSS protection, input validation, and secure output rendering
- **Jekyll Compatible**: Seamless integration with Jekyll static site generation
- **Responsive Layout**: CSS Grid-based responsive design
- **Accessibility Compliant**: WCAG-compatible screen reader and keyboard navigation

## 📋 Requirements

- Ruby 3.4+
- Bundler
- Jekyll 4.4+
- Git

## 🛠 Installation

```bash
# Clone the repository
git clone https://github.com/jbaruch/shownotes.git
cd shownotes

# Install dependencies  
bundle install

# Build the site
bundle exec jekyll build

# Serve locally
bundle exec jekyll serve
```

## 🧪 Testing

Comprehensive test suite with 139 tests covering all functionality:

```bash
# Run all tests
bundle exec rake test

# Run specific test categories
bundle exec rake test:unit          # Unit tests
bundle exec rake test:integration   # Integration tests  
bundle exec rake test:performance   # Performance tests
bundle exec rake test:e2e          # End-to-end tests

# Quick essential test run
bundle exec rake quick

# Detailed test summary
bundle exec rake test:all

# Show all available commands
bundle exec rake help
```

### Test Results

- **161 test runs, 1081 assertions**
- **0 failures, 0 errors, 0 skips**
- **100% success rate** ✅

## 📁 Project Structure

```
shownotes/
├── _config.yml                 # Jekyll configuration
├── _layouts/                   # Jekyll layout templates
├── _talks/                     # Talk content collection
├── assets/                     # CSS, JS, images
├── lib/                        # Core implementation
│   ├── talk_renderer.rb        # Main rendering engine
│   └── simple_talk_renderer.rb # Simplified renderer
├── test/                       # Comprehensive test suite
│   └── impl/
│       ├── unit/               # Unit tests (11 files)
│       ├── integration/        # Integration tests
│       ├── performance/        # Performance tests  
│       └── e2e/                # End-to-end tests
├── docs/                       # Project documentation
└── Rakefile                    # Test automation
```

## 🎯 Usage

### Creating Talk Pages

1. Add talk files to `_talks/` directory:
```yaml
---
title: "Modern JavaScript Patterns"
speaker: "Jane Developer"
conference: "JSConf 2024" 
date: "2024-03-15"
status: "completed"
resources:
  - type: "slides"
    title: "Presentation Slides"
    url: "https://slides.example.com"
  - type: "code" 
    title: "GitHub Repository"
    url: "https://github.com/example/repo"
  - type: "link"
    title: "Reference Documentation"
    url: "https://docs.example.com"
---

Talk description and additional content in Markdown format.
```

2. Build and deploy:
```bash
bundle exec jekyll build
```

### QR Code Integration

Generate QR codes pointing to talk URLs for conference presentations. Pages are optimized for quick mobile access during talks.

## 🔧 Development

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

## 🔒 Security

- **XSS Protection**: All user input properly escaped
- **Input Validation**: Comprehensive data validation  
- **Output Sanitization**: Safe HTML generation
- **Security Headers**: CSP, X-Frame-Options, etc.
- **URL Validation**: Prevents malicious link injection

## ⚡ Performance

- **Mobile Optimized**: Fast loading on mobile devices
- **Resource Efficient**: Minimized payload sizes
- **CDN Ready**: Static files optimized for CDN delivery
- **Progressive Enhancement**: Core functionality without JavaScript

## 📊 Test Coverage

### Unit Tests (129 runs, 789 assertions)
- Content rendering and Markdown processing
- Security validation and XSS protection  
- Responsive design and accessibility
- Data validation and error handling
- Navigation and user experience
- Resource management

### Integration Tests (16 runs, 206 assertions)
- Jekyll build process integration
- Template processing validation
- Configuration management

### Performance Tests (10 runs, 49 assertions)
- Page load time optimization
- Resource size management
- Mobile performance validation

### E2E Tests (6 runs, 37 assertions)  
- Complete user workflow validation
- QR code access scenarios
- Mobile user experience
- Error handling workflows

## 🤝 Support

For issues, questions, or contributions, please see the project documentation in the `docs/` directory or create an issue in the repository.

## 📄 License

This project is maintained by [Jonathan Baruch](https://github.com/jbaruch). Please contact the author for usage permissions.

---

**Built with test-first development** | **100% test coverage** | **Mobile-first design**