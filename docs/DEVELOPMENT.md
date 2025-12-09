# Development Guide

Complete development documentation for contributors to the Conference Talk Show Notes platform.

## Architecture Overview

### Current System Architecture

```text
Jekyll Static Site Generator
├── Content Management
│   ├── _talks/              # Individual talk files (Markdown)
│   ├── _layouts/            # Page templates
│   └── _includes/           # Reusable components
├── Processing Pipeline
│   ├── migrate_talk.rb      # Notist migration script
│   ├── lib/                 # Core Ruby libraries
│   └── utils/               # Helper scripts  
├── Static Assets
│   ├── assets/images/       # Thumbnails and media
│   ├── assets/css/          # Stylesheets
│   └── pdfs/                # PDF slides
└── Testing Framework
    ├── test/migration/      # Migration tests
    ├── test/impl/           # Implementation tests
    └── test/external/       # External service tests
```

### Key Components

#### Talk Processing Pipeline

1. **Migration Script** (`migrate_talk.rb`)
   - Fetches metadata from Notist API
   - Downloads thumbnails from og:image
   - Generates Jekyll-compatible Markdown
   - Validates content structure

2. **Jekyll Processing**
   - Builds static HTML from Markdown
   - Processes Liquid templates
   - Generates site navigation
   - Optimizes assets

3. **Local Thumbnail System**
   - Stores thumbnails in `assets/images/thumbnails/`
   - Uses `{talk-slug}-thumbnail.png` naming
   - Provides fallback placeholders
   - No external dependencies

#### Content Structure

```yaml
# Talk frontmatter structure
---
layout: talk
title: "Talk Title"
date: 2024-01-15
conference: "Conference Name"
slideshare_url: "https://..."
video_url: "https://..."
thumbnail_url: "/assets/images/thumbnails/talk-slug-thumbnail.png"
---

Talk content in Markdown...
```

## Development Practices

### Code Quality Standards

- **Ruby Style**: Follow standard Ruby conventions
- **Test Coverage**: Maintain comprehensive test coverage
- **Documentation**: Document all public APIs and complex logic
- **Security**: Follow secure coding practices for web applications

### Version Control

- **Branch Strategy**: Feature branches for development
- **Commit Messages**: Clear, descriptive commit messages
- **Code Review**: All changes should be reviewed
- **Testing**: All tests must pass before merging

### Jekyll Development

#### Local Development Setup

```bash
# Install dependencies
bundle install

# Start local server
bundle exec jekyll serve

# Run tests
bundle exec ruby test/run_tests.rb
```

#### Content Management

- **Talk Files**: Use clean markdown format with minimal frontmatter
- **Assets**: Store images, PDFs in appropriate directories
- **Layouts**: Maintain responsive, mobile-first designs
- **Performance**: Optimize for fast loading on conference networks

### Migration Development

#### Script Development

- **Single Script**: Use `migrate_talk.rb` as authoritative migration tool
- **Clean Format**: Generate minimal YAML frontmatter + clean markdown
- **Source Tracking**: Always include `source_url` for validation
- **Error Handling**: Robust error handling for network failures

#### Quality Assurance

- **Source Validation**: Compare against original noti.st content
- **Resource Counting**: Exclude slides/video from resource count
- **URL Validation**: Test all external links for accessibility
- **Format Consistency**: Ensure consistent markdown formatting

## AI Agent Guidelines

### Agent Persona: The Autonomous Developer

#### Decision Authority

- Make technical decisions independently
- Choose appropriate patterns and implementations
- Determine implementation details autonomously
- Never seek permission for standard development tasks

#### Code Quality Standards

- Write clean, maintainable, well-documented code
- Follow established patterns and conventions
- Ensure comprehensive test coverage
- Prioritize security and performance

#### Problem-Solving Approach

- Analyze problems thoroughly before implementing solutions
- Consider edge cases and error conditions
- Implement robust error handling
- Validate solutions with appropriate tests

### Development Workflow

#### Code Changes

1. **Analyze Requirements**: Understand the problem completely
2. **Design Solution**: Plan implementation approach
3. **Implement Changes**: Write clean, tested code
4. **Validate Results**: Ensure tests pass and functionality works
5. **Document Changes**: Update documentation as needed

#### Testing Strategy

- **Write Tests First**: Test-driven development approach
- **Comprehensive Coverage**: Unit, integration, and end-to-end tests
- **Real-World Validation**: Test with actual content and use cases
- **Performance Testing**: Ensure acceptable performance characteristics

#### Migration Quality

- **Source Comparison**: Always validate against original content
- **Resource Completeness**: Ensure all resources are migrated
- **Format Consistency**: Maintain clean, readable markdown format
- **URL Validation**: Verify all external links work properly

### Code Review Standards

#### Review Criteria

- **Functionality**: Code works as intended
- **Quality**: Follows coding standards and best practices
- **Testing**: Adequate test coverage and passing tests
- **Documentation**: Clear comments and updated documentation
- **Security**: No security vulnerabilities introduced

#### Performance Considerations

- **Load Times**: Optimize for fast page loading
- **Resource Usage**: Minimize memory and CPU usage
- **Network Efficiency**: Reduce external dependencies
- **Mobile Performance**: Ensure good performance on mobile devices

## Maintenance Procedures

### Regular Maintenance

#### Weekly Tasks

- Run full test suite to ensure system health
- Review and update documentation
- Check for broken external links
- Monitor performance metrics

#### Monthly Tasks

- Review test coverage and add missing tests
- Update dependencies and security patches
- Analyze migration quality and improve scripts
- Review and clean up temporary files and logs

#### Quarterly Tasks

- Comprehensive security review
- Performance optimization review
- Documentation comprehensive review
- Test strategy and coverage analysis

### Troubleshooting

#### Common Issues

**Jekyll Build Failures**

- Check Ruby version compatibility
- Verify all dependencies are installed
- Review Jekyll configuration
- Check for liquid syntax errors

**Migration Script Issues**

- Verify network connectivity to source URLs
- Check Google Drive API quotas and permissions
- Validate input URLs and format
- Review error logs for specific issues

**Test Failures**

- Ensure test environment is properly set up
- Check for external dependency issues
- Verify test data is current and valid
- Review test logs for specific failure causes

**Markdown Parser Plugin Issues**

The markdown parser plugin (`_plugins/markdown_parser.rb`) extracts metadata from talk markdown files. If production shows slugified filenames instead of proper titles, the plugin may not be executing correctly.

**Symptoms**:
- Talk titles show as "2025-10-01-conference-talk-name" instead of "Proper Talk Title"
- Missing conference names, dates, or video status on talk cards
- Missing "Highlighted Presentations" section on homepage
- Talk pages show only title and "Video Coming Soon" with no content

**Diagnosis Steps**:

1. **Verify plugin file exists**:
   ```bash
   ls -la _plugins/markdown_parser.rb
   ```

2. **Check plugin syntax**:
   ```bash
   ruby -c _plugins/markdown_parser.rb
   # Should output: Syntax OK
   ```

3. **Test plugin extraction locally**:
   ```bash
   bundle exec ruby test/impl/unit/markdown_parser_test.rb
   ```

4. **Build with verbose output**:
   ```bash
   bundle exec jekyll build --verbose 2>&1 | grep "MarkdownTalkProcessor"
   # Should show: "DEBUG: MarkdownTalkProcessor running in development environment"
   # Should show: "DEBUG: Found X talks"
   ```

5. **Check production build logs**:
   - Go to GitHub Actions → Latest deploy workflow
   - Check "Build with Jekyll" step for plugin output
   - Look for "MarkdownTalkProcessor" debug messages

**Common Causes and Fixes**:

1. **Plugin priority too low**:
   - Check `_plugins/markdown_parser.rb` has `priority :highest`
   - Lower priorities may cause plugin to run after templates render

2. **Plugin has syntax errors**:
   - Run `ruby -c _plugins/markdown_parser.rb` to check
   - Fix any syntax errors and redeploy

3. **Talk files missing required structure**:
   - Ensure talk files have H1 heading: `# Talk Title`
   - Ensure metadata uses bold format: `**Conference:** Name`
   - See `docs/templates/sample-talk.md` for correct format

4. **Jekyll not loading custom plugins**:
   - Verify `_plugins/` directory is not in `_config.yml` exclude list
   - Check that `safe: false` is not set in config (would disable custom plugins)
   - Ensure GitHub Actions workflow doesn't override plugin loading

5. **Production environment differences**:
   - Check if `JEKYLL_ENV=production` affects plugin behavior
   - Verify `--baseurl` flag in deploy workflow doesn't interfere
   - Test locally with production-like settings:
     ```bash
     JEKYLL_ENV=production bundle exec jekyll build --baseurl ""
     ```

**Prevention**:
- Run production health tests after deployments: `bundle exec ruby test/impl/e2e/production_health_test.rb`
- Monitor GitHub Actions logs for plugin execution
- Keep plugin debugging output for troubleshooting
- Test locally with production environment settings before deploying

#### Debugging Procedures

1. **Reproduce Issue**: Create minimal reproduction case
2. **Gather Information**: Collect logs, error messages, environment details
3. **Isolate Problem**: Identify specific component or code causing issue
4. **Implement Fix**: Make targeted fix with appropriate tests
5. **Validate Solution**: Ensure fix works and doesn't break other functionality

### Emergency Procedures

#### Site Down

1. Check Jekyll build status and logs
2. Verify hosting service status
3. Check DNS and domain configuration
4. Review recent changes for potential issues
5. Implement rollback if necessary

#### Data Loss

1. Identify scope and extent of loss
2. Check backup availability and integrity
3. Restore from most recent good backup
4. Verify restored data integrity
5. Implement additional backup procedures

## Development Tools

### Required Tools

- **Ruby**: Version 3.4+ for Jekyll compatibility
- **Bundler**: For dependency management
- **Git**: For version control
- **Text Editor**: VS Code, Vim, or similar
- **Browser**: For testing and development

### Recommended Tools

- **GitHub CLI**: For streamlined Git workflow
- **RuboCop**: For Ruby style checking
- **Jekyll Admin**: For content management interface
- **Google Chrome DevTools**: For debugging and performance analysis

### Development Environment

#### Local Setup

```bash
# Clone repository
git clone https://github.com/jbaruch/shownotes.git
cd shownotes

# Install dependencies
bundle install

# Start development server
bundle exec jekyll serve --livereload

# Run tests
bundle exec ruby test/run_tests.rb
```

#### Environment Variables

- **GOOGLE_API_KEY**: For Google Drive integration
- **JEKYLL_ENV**: Set to 'development' for local development
- **BUNDLE_PATH**: For gem installation directory

### Code Editor Configuration

#### VS Code Settings

```json
{
  "ruby.intellisense": "rubyLanguageServer",
  "ruby.format": "rubocop",
  "files.associations": {
    "*.md": "markdown"
  },
  "markdown.preview.breaks": true
}
```

#### Extensions

- Ruby Language Server
- Jekyll Snippets
- Markdown All in One
- GitLens

This comprehensive development guide ensures consistent, high-quality development practices for the shownotes project.
