# Design Document: Steering Files Refactor

## Overview

This design refactors the three steering files (tech.md, structure.md, product.md) to eliminate redundancy, improve organization, and provide comprehensive guidance to AI agents. The refactored files will maintain clear boundaries, include troubleshooting guidance, provide complete examples, and organize information by workflow rather than just reference.

## Architecture

### File Responsibilities

**product.md** - Business Context & User Workflows
- Product purpose and value proposition
- Target users and use cases
- Complete workflow descriptions (end-to-end)
- Feature descriptions with user benefits
- Decision criteria for workflow variations

**tech.md** - Technology & Operations
- Technology stack and versions
- Dependencies with purposes
- Command reference with examples
- Configuration files and their purposes
- Security considerations
- Troubleshooting guide
- Performance optimization guidance

**structure.md** - Code Organization & Patterns
- Directory structure with purposes
- File naming conventions with rationale
- Code patterns and examples
- Testing organization
- Build artifacts
- Anti-patterns to avoid

### Cross-Reference Strategy

Files will use markdown links to reference related information in other files:
- `See [Workflow Name](product.md#workflow-name)` for end-to-end process
- `See [Directory Structure](structure.md#directory-organization)` for file locations
- `See [Commands](tech.md#common-commands)` for execution details

## Components and Interfaces

### product.md Structure

```markdown
# Product Overview
- One-paragraph description
- Key differentiators

## Purpose & Value
- Problem being solved
- Target audience
- Core benefits

## Features
- Feature list with user benefits
- Technical capabilities

## User Workflows
### Quick Start Workflow
- Prerequisites
- Step-by-step with commands
- Expected outcomes
- Common issues

### Migration Workflow
- When to use
- Prerequisites
- Step-by-step
- Validation steps
- Troubleshooting

### Manual Creation Workflow
- When to use
- Step-by-step
- Best practices
- Examples

### Deployment Workflow
- Options comparison
- GitHub Pages setup
- Custom hosting setup
- Verification steps

## Decision Guides
- When to migrate vs manual creation
- When to use Google Drive vs local hosting
- Performance vs convenience trade-offs
```

### tech.md Structure

```markdown
# Technology Stack

## Core Technologies
- Technology: Version, Purpose, Why chosen

## Dependencies
### Production Dependencies
- Package: Purpose, When used

### Development Dependencies
- Package: Purpose, When used

## Command Reference

### Development Commands
#### bundle install
- Purpose
- When to run
- Expected output
- Common issues

[Repeat for each command]

### Testing Commands
[Same pattern]

### Migration Commands
[Same pattern]

## Configuration Files
### _config.yml
- Purpose
- Key sections
- Common modifications
- Validation

[Repeat for each config file]

## Build System
- Rake tasks overview
- Jekyll build process
- Dependency resolution

## Security
### Input Validation
- XSS protection approach
- YAML parsing safety
- URL validation

### Credentials Management
- Service account setup
- Credential storage
- .gitignore patterns

### External Services
- Google API authentication
- Rate limiting
- Error handling

## Performance
### Build Performance
- Fast build options
- Incremental builds
- Cache management

### Test Performance
- Quick test suite
- Full test suite
- When to use each

## Troubleshooting
### Dependency Issues
- Bundle install failures
- Version conflicts
- Platform-specific issues

### Build Issues
- Jekyll build failures
- Plugin errors
- Template errors

### Migration Issues
- API authentication
- Network timeouts
- Content parsing errors

### Test Issues
- Test failures
- Environment setup
- Browser driver issues
```

### structure.md Structure

```markdown
# Project Structure

## Directory Organization
[Current tree with enhanced comments]

## File Patterns

### Talk Files
- Location and purpose
- Naming convention with rationale
- Format specification
- Frontmatter schema
- Content structure
- Examples (good and bad)

### Thumbnail Files
- Location and purpose
- Naming convention
- Format requirements
- Size recommendations
- Fallback behavior
- Generation process

### Layout Files
- Purpose of each layout
- Template variables available
- Customization points

### Library Files
- talk_renderer.rb purpose and usage
- simple_talk_renderer.rb purpose and usage
- When to use each

## Content Conventions

### Talk File Format
[Complete example with annotations]

### Frontmatter Schema
- Required fields
- Optional fields
- Field validation rules
- Examples

### Markdown Conventions
- Heading hierarchy
- Link formats
- Resource lists
- Code blocks

## Testing Structure

### Test Organization
- Unit test location and purpose
- Integration test location and purpose
- E2E test location and purpose
- Migration test location and purpose
- External test location and purpose

### Test Naming
- File naming pattern
- Test method naming
- Fixture naming

### Test Patterns
- Setup/teardown patterns
- Assertion patterns
- Mock usage guidelines

## Build Artifacts

### Generated Directories
- _site/: Purpose, when created, git status
- _test_site/: Purpose, when created, git status
- _perf_test_site/: Purpose, when created, git status
- .jekyll-cache/: Purpose, when created, git status

### Cleaning Artifacts
- Commands to clean
- When to clean
- What to preserve

## Naming Conventions

### Convention Table
| Type | Convention | Example | Rationale |
|------|-----------|---------|-----------|
| Talk files | date-kebab-case.md | 2025-10-01-conf-talk.md | Chronological sorting |
| Thumbnails | slug-thumbnail.ext | conf-talk-thumbnail.png | Matches talk file |
| Ruby files | snake_case.rb | talk_renderer.rb | Ruby convention |
| CSS classes | kebab-case | .talk-header | Web standard |
| Test files | *_test.rb | renderer_test.rb | Minitest convention |

## Anti-Patterns

### What to Avoid
- Hardcoded paths (use Jekyll variables)
- Inline styles (use CSS classes)
- Duplicate content (use includes)
- Manual thumbnail management (use migration script)
- Direct HTML in markdown (use markdown syntax)

### Why These Are Problems
[Explanation for each]

### Correct Alternatives
[Better approach for each]
```

## Data Models

### Steering File Metadata

```yaml
file: string              # Filename
purpose: string           # Primary responsibility
target_audience: string   # Who uses this file
update_frequency: string  # How often it changes
dependencies: [string]    # Other files it references
```

### Content Section

```yaml
section: string           # Section heading
type: enum                # reference|workflow|troubleshooting|example
priority: enum            # critical|important|nice-to-have
completeness: enum        # complete|partial|missing
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Based on the prework analysis, most acceptance criteria require domain knowledge and manual review rather than automated property testing. However, we can define properties for the structural and syntactic aspects:

### Property 1: No Information Duplication

*For any* factual statement (command syntax, file path, configuration value, version number), it should appear in exactly one steering file as the primary source. If the same fact appears in multiple files, at least one occurrence must be a cross-reference link.

**Validates: Requirements 1.1, 1.4**

**Testing approach:** Parse all three markdown files, extract factual statements (code blocks, inline code, specific values), create a hash of each unique fact, and verify each hash appears only once as primary content (non-link).

### Property 2: Cross-Reference Link Validity

*For any* markdown link that references another steering file (e.g., `[text](product.md#section)`), the target file and section anchor should exist.

**Validates: Requirements 1.2**

**Testing approach:** Extract all internal links from steering files, parse target files to find section headings, verify each link target exists.

### Property 3: File Boundary Compliance

*For any* top-level section in tech.md, its content should be categorizable as technology/dependency/command/configuration. *For any* top-level section in structure.md, its content should be categorizable as directory/file-pattern/naming/organization. *For any* top-level section in product.md, its content should be categorizable as purpose/feature/workflow/user-context.

**Validates: Requirements 2.1, 2.2, 2.3**

**Testing approach:** Define allowed section categories for each file, parse section headings, verify each section matches an allowed category using keyword matching.

### Property 4: Command Example Completeness

*For any* command example (bash code block or inline command), there should be accompanying text within the same section that describes expected output, success indicators, or purpose.

**Validates: Requirements 3.1**

**Testing approach:** Extract all code blocks and inline code that look like commands (start with common command names), check that surrounding text contains keywords like "output", "result", "success", "purpose", "when", or "expected".

### Property 5: Example Syntax Validity

*For any* code example marked with a language (```yaml, ```ruby, ```bash, ```markdown), the content should be syntactically valid for that language.

**Validates: Requirements 5.1**

**Testing approach:** Extract code blocks with language markers, use appropriate parsers/linters (YAML parser, Ruby syntax checker, bash syntax checker) to validate syntax.

**Note on Property Testing:** The remaining acceptance criteria (2.4, 3.2-3.4, 4.1-4.4, 5.2-5.4, 6.1-6.4, 7.1-7.4, 8.1-8.4) require domain knowledge, semantic understanding, or subjective judgment. These will be validated through manual review and usability testing rather than automated property tests.

## Error Handling

### Missing Information Detection
- During refactoring, identify gaps in current documentation
- Flag sections that need examples or troubleshooting
- Prioritize critical vs nice-to-have additions

### Validation Approach
- Manual review of each section for completeness
- Cross-reference validation (all links work)
- Example validation (all examples are correct)
- Consistency check (terminology, formatting)

### Handling Ambiguous Categorization
- If content could fit multiple files, use primary responsibility:
  - User-facing workflow → product.md
  - Technical execution → tech.md
  - Code organization → structure.md
- Add cross-references from other relevant files

## Testing Strategy

### Manual Review Tests
- Read each file independently for clarity
- Verify no duplicate information exists
- Check all cross-references resolve correctly
- Validate all examples are complete and correct

### Completeness Tests
- Each requirement has corresponding content
- Each workflow has all required sections
- Each command has purpose and expected output
- Each troubleshooting section covers common issues

### Consistency Tests
- Terminology is consistent across files
- Formatting follows same patterns
- Code examples use same style
- Cross-references use same format

### Usability Tests
- Can an AI agent find information quickly?
- Are workflows easy to follow?
- Are examples copy-pasteable?
- Is troubleshooting guidance actionable?

## Implementation Notes

### Refactoring Approach
1. Create new versions of all three files
2. Extract all unique information from current files
3. Categorize each piece of information
4. Organize within appropriate file structure
5. Add missing information (troubleshooting, examples, workflows)
6. Add cross-references where needed
7. Validate completeness and correctness
8. Replace old files with new versions

### Content Additions Needed
- Troubleshooting sections for common issues
- Complete workflow descriptions with decision points
- Expected output for all commands
- Rationale for conventions and patterns
- Anti-patterns section in structure.md
- Performance guidance in tech.md
- Decision guides in product.md

### Preservation Requirements
- All existing factual information must be preserved
- No information should be lost in refactoring
- Current examples should be enhanced, not replaced
- Existing cross-references should be maintained or improved
