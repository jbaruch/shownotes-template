# Implementation Plan

## Overview

This plan outlines the steps to sync template-worthy changes from the shownotes main repository to the shownotes-template repository while preserving instance-specific configurations.

## Tasks

- [x] 1. Prepare template repository for sync
  - Create feature branch in template repository
  - Verify template is in clean state with all tests passing
  - Document current template state
  - _Requirements: 4.1, 4.3_

- [x] 1.1 Clean up template content
  - Remove all personal talk files from _talks/ directory (keep directory structure)
  - Remove all personal thumbnails from assets/images/thumbnails/ (keep placeholder-thumbnail.svg only)
  - Verify sample-talk.md exists only in docs/templates/ (not in _talks/)
  - Add .gitkeep to _talks/ if directory is empty
  - _Requirements: 3.4, 3.5_

- [x] 2. Cherry-pick plugin improvements commit
  - Cherry-pick commit 1f977c6 to template feature branch
  - Verify plugin debugging output works correctly
  - Verify error handling prevents crashes
  - Verify .gitignore excludes sample-talk.md
  - _Requirements: 1.2, 2.1, 4.1_

- [x] 3. Cherry-pick documentation updates commit
  - Cherry-pick commit bb100cf to template feature branch
  - Verify all documentation uses generic examples
  - Verify sample talk template has placeholder data
  - Verify documentation references are correct
  - _Requirements: 1.2, 2.4, 3.3_

- [-] 4. Validate template configuration
  - Review _config.yml to ensure placeholder values are present
  - Verify url is "https://jbaruch.github.io"
  - Verify baseurl is "/shownotes"
  - Ensure no instance-specific values leaked in
  - _Requirements: 3.1, 3.2, 3.5_

- [ ] 5. Run template validation tests
  - Run `bundle install` in template repository
  - Run `bundle exec jekyll build` and verify success
  - Run `bundle exec rake test` and verify all tests pass
  - Manually test sample talk renders correctly
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 6. Review all file changes
  - Review each modified file for instance-specific content
  - Verify documentation uses generic language
  - Check that test files don't reference personal data
  - Ensure sample content uses placeholder URLs
  - **Verify _talks/ directory is empty (no personal talks)**
  - **Verify only placeholder-thumbnail.svg in assets/images/thumbnails/**
  - **Verify sample-talk.md is only in docs/templates/**
  - _Requirements: 3.3, 3.4, 5.1_

- [ ] 7. Push changes to template repository
  - Push feature branch to template remote
  - Create pull request with detailed description
  - Document what was synced and why
  - List all commits and file changes
  - _Requirements: 5.1, 5.2, 5.5_

- [ ] 8. Final validation before merge
  - Review pull request changes one more time
  - Verify no instance-specific config in diff
  - Check that all tests pass in CI
  - Confirm documentation is complete
  - _Requirements: 4.1, 4.4, 5.3_

- [ ] 9. Merge and tag release
  - Merge pull request to template/main
  - Tag release with version number
  - Update template CHANGELOG
  - Document breaking changes if any
  - _Requirements: 5.4, 5.5_

- [ ] 10. Update template documentation
  - Update README with new features if applicable
  - Document any new configuration options
  - Update migration guide if breaking changes
  - Verify all documentation links work
  - _Requirements: 5.3, 5.4_

## Notes

- **Do NOT sync commit cc5710f** - it contains instance-specific custom domain configuration
- **Preserve template placeholder values** - url and baseurl must remain generic
- **Remove all personal talks from template** - _talks/ should be empty or have only .gitkeep
- **Remove all personal thumbnails** - only placeholder-thumbnail.svg should remain
- **Sample talk location** - sample-talk.md should only be in docs/templates/ (as a reference)
- **Test thoroughly** - template must work for new users out of the box
- **Document changes** - clear commit messages and PR description are essential

## Success Criteria

- ✅ Template repository has all bug fixes and improvements from main
- ✅ Template configuration uses placeholder values (not jbaruch-specific)
- ✅ **_talks/ directory is empty (no personal conference talks)**
- ✅ **Only placeholder-thumbnail.svg in assets/images/thumbnails/**
- ✅ **sample-talk.md exists only in docs/templates/ as a reference**
- ✅ All tests pass in template repository
- ✅ Sample talk template has placeholder data
- ✅ Documentation is complete and uses generic examples
- ✅ New users can fork template and customize without issues
