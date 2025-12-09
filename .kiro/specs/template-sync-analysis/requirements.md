# Requirements Document

## Introduction

This specification addresses the need to analyze changes between the shownotes repository and its upstream template (shownotes-template), determine which changes should be synchronized to the template for reuse by other users, and which changes are instance-specific and should remain only in the main repository.

## Glossary

- **Shownotes Repository**: The main repository (jbaruch/shownotes) containing a specific speaker's conference talk website
- **Template Repository**: The upstream template repository (jbaruch/shownotes-template) that serves as a starting point for other speakers
- **Instance-Specific Changes**: Modifications that are unique to a particular speaker's site (e.g., custom domain, speaker profile, specific talks)
- **Template-Worthy Changes**: Improvements, bug fixes, and features that benefit all users of the template
- **Sync**: The process of pushing appropriate changes from the main repository back to the template repository

## Requirements

### Requirement 1

**User Story:** As a template maintainer, I want to identify which changes in the main repository should be pushed to the template, so that other users can benefit from improvements and bug fixes.

#### Acceptance Criteria

1. WHEN analyzing commits between main and template/main THEN the system SHALL categorize each change as either template-worthy or instance-specific
2. WHEN a change fixes a bug or adds a feature THEN the system SHALL mark it as template-worthy
3. WHEN a change contains configuration specific to one speaker THEN the system SHALL mark it as instance-specific
4. WHEN a change contains both template-worthy and instance-specific modifications THEN the system SHALL identify which parts should be extracted
5. WHEN the analysis is complete THEN the system SHALL provide a clear list of changes to push to the template

### Requirement 2

**User Story:** As a template maintainer, I want to understand the impact of each change, so that I can make informed decisions about what to sync to the template.

#### Acceptance Criteria

1. WHEN reviewing a change THEN the system SHALL describe what the change does and why it was made
2. WHEN a change affects multiple files THEN the system SHALL list all affected files and their purposes
3. WHEN a change has dependencies THEN the system SHALL identify related changes that must be synced together
4. WHEN a change improves documentation THEN the system SHALL indicate which documentation files are affected
5. WHEN a change adds or modifies tests THEN the system SHALL describe the test coverage impact

### Requirement 3

**User Story:** As a template maintainer, I want to preserve instance-specific configurations, so that the template remains generic and reusable for other speakers.

#### Acceptance Criteria

1. WHEN syncing changes to the template THEN the system SHALL exclude speaker-specific configuration values
2. WHEN syncing _config.yml changes THEN the system SHALL preserve template placeholder values for url and baseurl
3. WHEN syncing documentation THEN the system SHALL use generic examples rather than specific speaker names
4. WHEN syncing sample content THEN the system SHALL ensure it uses placeholder data
5. WHEN the sync is complete THEN the template SHALL remain ready for new users to fork and customize

### Requirement 4

**User Story:** As a template maintainer, I want to ensure the template repository stays functional, so that new users have a working starting point.

#### Acceptance Criteria

1. WHEN pushing changes to the template THEN the system SHALL verify all tests pass
2. WHEN updating the template THEN the system SHALL ensure the sample talk renders correctly
3. WHEN modifying configuration THEN the system SHALL validate the template builds successfully
4. WHEN adding new features THEN the system SHALL include corresponding documentation updates
5. WHEN the template is updated THEN the system SHALL verify GitHub Pages deployment works

### Requirement 5

**User Story:** As a template user, I want clear documentation of what changed in the template, so that I can decide whether to pull updates into my fork.

#### Acceptance Criteria

1. WHEN changes are pushed to the template THEN the system SHALL create descriptive commit messages
2. WHEN multiple related changes are synced THEN the system SHALL group them logically
3. WHEN a change affects user workflows THEN the system SHALL update relevant documentation
4. WHEN breaking changes are introduced THEN the system SHALL document migration steps
5. WHEN the template is updated THEN the system SHALL provide a summary of improvements

### Requirement 6

**User Story:** As a template user, I want the template to contain only example content and no personal talks, so that I have a clean starting point for my own conference talks.

#### Acceptance Criteria

1. WHEN the template is prepared THEN the system SHALL remove all personal talk files from _talks/ directory
2. WHEN the template is prepared THEN the system SHALL remove all personal thumbnails except placeholder-thumbnail.svg
3. WHEN the template is prepared THEN the system SHALL ensure sample-talk.md exists only in docs/templates/ as a reference
4. WHEN a new user forks the template THEN the _talks/ directory SHALL be empty or contain only .gitkeep
5. WHEN the template is validated THEN the system SHALL verify no personal content remains in the template
