# Shownotes Project Structure

This document provides an overview of the organized project structure after comprehensive cleanup and reorganization.

## Root Directory

```
├── README.md                    # Main project documentation
├── index.md                     # Main site content
├── _config.yml                  # Jekyll configuration
├── Gemfile                      # Ruby dependencies
├── Rakefile                     # Rake tasks
└── PROJECT-STRUCTURE.md         # This file
```

## Content Directories

```
├── _talks/                      # Individual talk markdown files
├── _layouts/                    # Jekyll page layouts
├── _includes/                   # Jekyll includes/partials
├── _plugins/                    # Jekyll plugins
├── assets/                      # Static assets (CSS, images)
├── lib/                         # Ruby library files
└── pdfs/                        # PDF storage directory
```

## Documentation (docs/)

```
docs/
├── MIGRATION.md                 # Complete migration workflow guide
├── TESTING.md                   # Test suite documentation and guide
└── DEVELOPMENT.md               # Development setup and contribution guide
```

## Test Suite (test/)

Organized test suite with 45+ test files in logical categories:

```
test/
├── run_tests.rb                 # Main test runner with category support
├── README.md                    # Test suite documentation
├── impl/                        # Implementation tests
│   ├── unit/                    # Unit tests (20 files)
│   ├── integration/             # Integration tests (5 files)
│   ├── e2e/                     # End-to-end tests (2 files)
│   └── performance/             # Performance tests (1 file)
├── migration/                   # Migration-specific tests (3 files)
├── external/                    # External service tests (2 files)
└── tools/                       # Tool/utility tests (2 files)
```

## Utilities (utils/)

Organized utility scripts for migration and maintenance:

```
utils/
├── README.md                    # Comprehensive utility documentation
├── migration/                   # Migration tools
│   └── migrate_talk.rb          # Main migration script
└── google_drive/                # Google Drive management
    ├── cleanup_google_drive.rb  # Clean up drive folder
    ├── delete_google_drive_file.rb  # Delete specific files
    └── force_delete_files.rb    # Force delete operations
```

## Key Features

### Test Organization
- **40+ tests** organized into logical categories
- **Unified test runner** with category-based execution
- **Clear separation** between unit, integration, e2e, and external tests

### Documentation Consolidation
- **3 comprehensive guides** replacing 15+ scattered files
- **Logical organization** by purpose (migration, testing, development)
- **Cross-referenced** documentation with consistent formatting

### Utility Organization
- **Migration tools** separated from Google Drive utilities
- **Comprehensive documentation** with usage examples
- **Proper path handling** for scripts in subdirectories

### Clean Root Directory
- **Only essential files** in root (README.md, index.md, configs)
- **No scattered test files** or utility scripts
- **Clear separation of concerns** across directory structure

## Usage Examples

### Running Tests
```bash
# Run all tests
ruby test/run_tests.rb

# Run specific category
ruby test/run_tests.rb --category unit
ruby test/run_tests.rb --category integration
```

### Migration
```bash
# Migrate a talk
cd /Users/jbaruch/Projects/shownotes
ruby utils/migration/migrate_talk.rb "https://speaking.jbaru.ch/talk/abcdef"
```

### Google Drive Cleanup
```bash
# Clean up drive folder
ruby utils/google_drive/cleanup_google_drive.rb
```

This organized structure provides clear separation of concerns, easy navigation, and maintainable codebase for the Jekyll-based shownotes project.
