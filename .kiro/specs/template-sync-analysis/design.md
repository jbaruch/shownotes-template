# Design Document

## Overview

This design analyzes the divergence between the shownotes main repository and the shownotes-template repository, categorizes changes, and provides a plan for syncing appropriate improvements back to the template while preserving instance-specific customizations.

## Current State Analysis

### Commit Divergence

The main repository is 3 commits ahead of template/main:

1. **bb100cf** - "Complete website-health-check spec: Update documentation"
2. **1f977c6** - "Fix production website issues: add plugin debugging, error handling, and exclude sample talk"
3. **cc5710f** - "Fix: Correct URL and baseurl for custom domain"

### File Changes Summary

**Configuration Files:**
- `_config.yml`: Changed url and baseurl for custom domain (instance-specific)

**Plugin Files:**
- `_plugins/markdown_parser.rb`: Added debugging, error handling, priority change (template-worthy)

**Documentation Files:**
- `docs/DEVELOPMENT.md`: Added plugin troubleshooting (template-worthy)
- `docs/SETUP.md`: Added sample talk template reference (template-worthy)
- `docs/TESTING.md`: Added production health tests section (template-worthy)
- `docs/templates/sample-talk.md`: Created sample talk template (template-worthy)

**Test Files:**
- `test/impl/e2e/production_health_test.rb`: New production health tests (template-worthy)
- `test/impl/unit/markdown_parser_test.rb`: Enhanced plugin tests (template-worthy)

**Build Configuration:**
- `.gitignore`: Added sample-talk.md exclusion (template-worthy)

## Architecture

### Change Categories

#### Category 1: Template-Worthy Changes
Changes that improve the template for all users:
- Bug fixes in core functionality
- Enhanced error handling
- Improved documentation
- Better testing infrastructure
- Sample content and templates

#### Category 2: Instance-Specific Changes
Changes unique to the jbaruch instance:
- Custom domain configuration (speaking.jbaru.ch)
- Speaker-specific URLs and baseurls
- Personal talk content

#### Category 3: Hybrid Changes
Changes containing both template-worthy and instance-specific elements:
- Commits that fix bugs but also include configuration changes
- Documentation updates that reference specific instances

## Components and Interfaces

### Component 1: Change Analyzer

**Purpose:** Categorize each commit and file change

**Interface:**
```ruby
class ChangeAnalyzer
  def analyze_commit(commit_sha)
    # Returns: { template_worthy: [], instance_specific: [], hybrid: [] }
  end
  
  def extract_template_changes(hybrid_changes)
    # Returns: List of changes safe to push to template
  end
end
```

### Component 2: Template Synchronizer

**Purpose:** Apply template-worthy changes to the template repository

**Interface:**
```ruby
class TemplateSynchronizer
  def cherry_pick_changes(changes)
    # Cherry-picks specific commits or file changes
  end
  
  def create_sync_branch
    # Creates a branch for template updates
  end
  
  def validate_template
    # Runs tests and builds to ensure template works
  end
end
```

## Data Models

### Change Classification

```yaml
commit: bb100cf
message: "Complete website-health-check spec: Update documentation"
classification: template_worthy
files:
  - path: docs/DEVELOPMENT.md
    status: template_worthy
    reason: "Generic plugin troubleshooting guidance"
  - path: docs/SETUP.md
    status: template_worthy
    reason: "Sample talk template reference"
  - path: docs/TESTING.md
    status: template_worthy
    reason: "Production health test documentation"
  - path: docs/templates/sample-talk.md
    status: template_worthy
    reason: "Reusable sample talk template"
```

```yaml
commit: 1f977c6
message: "Fix production website issues: add plugin debugging, error handling, and exclude sample talk"
classification: template_worthy
files:
  - path: _plugins/markdown_parser.rb
    status: template_worthy
    reason: "Bug fixes and error handling benefit all users"
  - path: .gitignore
    status: template_worthy
    reason: "Prevents sample talk from appearing in production"
  - path: test/impl/unit/markdown_parser_test.rb
    status: template_worthy
    reason: "Enhanced test coverage for plugin"
  - path: test/impl/e2e/production_health_test.rb
    status: template_worthy
    reason: "New health check tests for production sites"
```

```yaml
commit: cc5710f
message: "Fix: Correct URL and baseurl for custom domain"
classification: instance_specific
files:
  - path: _config.yml
    status: instance_specific
    reason: "Custom domain configuration specific to jbaruch"
    note: "Template should keep placeholder values"
```

## Detailed Change Analysis

### Commit bb100cf: Documentation Updates

**Template-Worthy Elements:**
- ✅ All documentation updates are generic and helpful for all users
- ✅ Plugin troubleshooting guide applies to any template user
- ✅ Sample talk template is reusable
- ✅ Production health test documentation is valuable for all

**Action:** Push entire commit to template

### Commit 1f977c6: Plugin Fixes and Health Tests

**Template-Worthy Elements:**
- ✅ Plugin debugging output helps all users troubleshoot
- ✅ Error handling with fallback values prevents crashes
- ✅ Priority change from :high to :highest fixes execution order
- ✅ Moving sample-talk.md to docs/templates/ is correct structure
- ✅ .gitignore update prevents accidental sample talk publication
- ✅ Enhanced plugin tests improve reliability
- ✅ Production health tests validate live sites

**Action:** Push entire commit to template

### Commit cc5710f: Custom Domain Configuration

**Instance-Specific Elements:**
- ❌ URL change to speaking.jbaru.ch is personal
- ❌ Baseurl removal is specific to custom domain setup

**Template Values:**
- Template should keep: `url: "https://jbaruch.github.io"`
- Template should keep: `baseurl: "/shownotes"`

**Action:** Do NOT push this commit to template

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Template Genericity Preservation

*For any* change pushed to the template, the template SHALL NOT contain instance-specific configuration values (custom domains, speaker names, personal URLs)

**Validates: Requirements 3.1, 3.2, 3.3**

### Property 2: Template Functionality Preservation

*For any* change pushed to the template, running `bundle exec jekyll build` on the template SHALL succeed without errors

**Validates: Requirements 4.1, 4.2, 4.3**

### Property 3: Test Coverage Maintenance

*For any* change pushed to the template, running `bundle exec rake test` SHALL pass all tests

**Validates: Requirements 4.1**

### Property 4: Documentation Completeness

*For any* feature or bug fix pushed to the template, corresponding documentation updates SHALL be included in the same commit or pull request

**Validates: Requirements 5.1, 5.3**

### Property 5: Sample Content Validity

*For any* sample content in the template, it SHALL use placeholder data and working example URLs (not broken links or personal content)

**Validates: Requirements 3.4, 4.2**

## Error Handling

### Merge Conflicts

**Scenario:** Template has diverged and cherry-picking causes conflicts

**Handling:**
1. Create a feature branch in template repository
2. Manually resolve conflicts preserving template values
3. Run full test suite
4. Review changes before merging

### Test Failures

**Scenario:** Tests fail after syncing changes to template

**Handling:**
1. Identify which tests are failing
2. Determine if failure is due to instance-specific assumptions
3. Update tests to work with template placeholder values
4. Re-run test suite until all pass

### Configuration Contamination

**Scenario:** Instance-specific config accidentally pushed to template

**Handling:**
1. Immediately revert the commit
2. Create new commit with corrected configuration
3. Force push to template (if not yet pulled by users)
4. Document the correction in commit message

## Testing Strategy

### Unit Tests

**Existing Tests:**
- Plugin extraction methods (markdown_parser_test.rb)
- Utility modules (date_validator, url_validator, etc.)

**New Tests Needed:**
- None - existing tests are comprehensive

### Integration Tests

**Existing Tests:**
- Jekyll build validation
- Content rendering
- Renderer integration

**New Tests Needed:**
- None - existing tests cover integration

### End-to-End Tests

**Existing Tests:**
- Production health checks (production_health_test.rb)
- Browser-based navigation tests

**New Tests Needed:**
- None - production health tests were just added

### Property-Based Tests

**Not applicable for this sync operation** - this is a one-time analysis and sync task, not ongoing code that requires property-based testing.

### Validation Tests

**Template Validation Checklist:**
1. ✅ Clone template repository
2. ✅ Run `bundle install`
3. ✅ Run `bundle exec jekyll build`
4. ✅ Run `bundle exec rake test`
5. ✅ Verify sample talk renders correctly
6. ✅ Check that placeholder values are present in _config.yml
7. ✅ Verify documentation is up to date
8. ✅ Test GitHub Pages deployment

## Implementation Plan

### Phase 1: Prepare Template Repository

1. Fetch latest from template remote
2. Create feature branch: `sync-from-main-dec-2024`
3. Verify template is in clean state
4. **Clean up template content:**
   - Remove all personal talk files from _talks/
   - Remove all personal thumbnails from assets/images/thumbnails/ (keep placeholder-thumbnail.svg)
   - Ensure sample-talk.md is only in docs/templates/ (not in _talks/)

### Phase 2: Cherry-Pick Template-Worthy Commits

1. Cherry-pick commit 1f977c6 (plugin fixes and health tests)
2. Cherry-pick commit bb100cf (documentation updates)
3. Skip commit cc5710f (instance-specific config)

### Phase 3: Validate Template

1. Run `bundle install` in template
2. Run `bundle exec jekyll build`
3. Run `bundle exec rake test`
4. Manually review _config.yml for placeholder values
5. Check docs/templates/sample-talk.md renders correctly

### Phase 4: Push to Template

1. Push feature branch to template repository
2. Create pull request with detailed description
3. Review changes one final time
4. Merge to template/main
5. Tag release if significant changes

### Phase 5: Document Sync

1. Update template CHANGELOG
2. Document what was synced and why
3. Note any breaking changes or migration steps
4. Update template README if needed

## Recommendations

### What Should Be Pushed to Template

**High Priority (Push Immediately):**
1. ✅ Plugin debugging and error handling improvements
2. ✅ Production health tests
3. ✅ Enhanced plugin unit tests
4. ✅ Documentation updates (DEVELOPMENT.md, SETUP.md, TESTING.md)
5. ✅ Sample talk template (docs/templates/sample-talk.md)
6. ✅ .gitignore update for sample-talk.md

**Rationale:** These are all bug fixes, improvements, and documentation that benefit every template user.

### What Should NOT Be Pushed to Template

**Instance-Specific (Keep in Main Only):**
1. ❌ Custom domain URL (speaking.jbaru.ch)
2. ❌ Empty baseurl (specific to custom domain)
3. ❌ Any speaker-specific talk files in _talks/ (all actual conference talks)
4. ❌ Personal thumbnails in assets/images/thumbnails/

**Rationale:** These are specific to the jbaruch instance and would break the template for new users.

### What Should Be REMOVED from Template

**Currently in Template but Shouldn't Be:**
1. ❌ All actual talk files in _talks/ directory (50+ personal talks)
2. ❌ All personal thumbnails in assets/images/thumbnails/

**What Template Should Have Instead:**
1. ✅ Only the sample-talk.md in docs/templates/ (as a reference)
2. ✅ Empty _talks/ directory (or with .gitkeep)
3. ✅ Only placeholder-thumbnail.svg in assets/images/thumbnails/

**Rationale:** The template should be a clean starting point. Users fork it and add their own talks. Having 50+ personal talks in the template is confusing and makes it harder for new users to understand what to do.

### Configuration File Handling

**_config.yml in Template Should Have:**
```yaml
url: "https://jbaruch.github.io"
baseurl: "/shownotes"
hero_background: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1920"

# Jekyll configuration
title: "Conference Talk Show Notes"
description: "Mobile-optimized conference talk pages"
# ... rest of generic config
```

**_config.yml in Main Can Have:**
```yaml
url: "https://speaking.jbaru.ch"
baseurl: ""
# ... personal configuration
```

## Risk Analysis

### Risk 1: Breaking Template for Existing Users

**Likelihood:** Low  
**Impact:** High  
**Mitigation:** 
- Run full test suite before pushing
- Test fresh clone of template
- Document any breaking changes
- Provide migration guide if needed

### Risk 2: Accidentally Pushing Instance-Specific Config

**Likelihood:** Medium  
**Impact:** High  
**Mitigation:**
- Carefully review each file change
- Use cherry-pick instead of merge
- Double-check _config.yml values
- Have second person review before merge

### Risk 3: Merge Conflicts

**Likelihood:** Low (template hasn't diverged much)  
**Impact:** Medium  
**Mitigation:**
- Use feature branch for sync
- Resolve conflicts carefully
- Test after resolution
- Keep commits atomic

## Future Considerations

### Automated Sync Process

Consider creating a script or GitHub Action that:
1. Identifies template-worthy commits automatically
2. Flags instance-specific changes
3. Creates pull requests to template
4. Runs validation tests

### Sync Frequency

**Recommendation:** Sync to template after:
- Bug fixes that affect core functionality
- New features that benefit all users
- Documentation improvements
- Test infrastructure enhancements

**Avoid syncing:**
- Personal content additions
- Instance-specific configuration tweaks
- Experimental changes not yet proven

### Bidirectional Sync

Currently sync is one-way (main → template). Consider:
- Pulling template updates back to main periodically
- Keeping main in sync with template improvements
- Using merge strategy to track template relationship
