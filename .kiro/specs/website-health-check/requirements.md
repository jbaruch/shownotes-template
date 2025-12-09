# Requirements Document

## Introduction

The shownotes website has critical issues on production (speaking.jbaru.ch) that prevent proper display of talk content. The site is missing content rendering, showing incorrect titles, and includes template files that should not be deployed. This feature will fix production deployment issues and add tests to prevent regression.

## Glossary

- **Production Site**: The live website at speaking.jbaru.ch
- **Local Build**: Jekyll site built and served locally at localhost:4000
- **Talk Page**: Individual page displaying a conference talk with slides, video, and resources
- **Index Page**: Homepage listing all talks with highlighted presentations section
- **Sample Talk**: Template file (_talks/sample-talk.md) used for documentation, should not appear on production
- **Jekyll**: Static site generator that processes markdown files into HTML
- **GitHub Pages**: Hosting service that builds and deploys the Jekyll site

## Requirements

### Requirement 1

**User Story:** As a site visitor, I want to see properly formatted talk content on the production site matching the local build, so that I can access talk information and resources.

#### Acceptance Criteria

1. WHEN a user visits the production homepage THEN the system SHALL display a "Highlighted Presentations" section with the 3 most recent talks
2. WHEN a user views a talk card on production THEN the system SHALL display the talk title extracted from the H1 heading in the markdown file
3. WHEN a user views a talk card on production THEN the system SHALL display the conference name, date, and video status formatted with proper labels and emojis
4. WHEN a user views a talk page on production THEN the system SHALL display the full talk content including slides, video embeds, abstract, and resources
5. WHEN a user views a talk page on production THEN the system SHALL show the actual talk title from the markdown H1, not the slugified filename

### Requirement 2

**User Story:** As a site maintainer, I want the sample-talk.md template file excluded from production builds, so that documentation examples don't appear as real talks on the live site.

#### Acceptance Criteria

1. WHEN Jekyll builds the site THEN the system SHALL exclude _talks/sample-talk.md from the _site output directory
2. WHEN the sample talk file is added to .gitignore THEN the system SHALL prevent it from being committed to the repository
3. WHEN a user visits the production homepage THEN the system SHALL NOT display the sample talk in the talks list
4. WHEN a user attempts to access /talks/sample-talk/ on production THEN the system SHALL return a 404 error
5. WHEN a developer needs a template THEN the system SHALL provide sample-talk.md in documentation or a separate templates directory

### Requirement 3

**User Story:** As a developer, I want automated tests that verify production site health, so that deployment issues are caught before users encounter them.

#### Acceptance Criteria

1. WHEN tests run THEN the system SHALL verify the homepage loads successfully with HTTP 200 status
2. WHEN tests run THEN the system SHALL verify CSS is loaded and applied correctly
3. WHEN tests run THEN the system SHALL verify at least one talk page loads with proper content
4. WHEN tests run THEN the system SHALL verify the sample talk does not appear in production builds
5. WHEN tests run THEN the system SHALL verify talk titles are extracted from markdown H1 headings, not filenames
6. WHEN tests run THEN the system SHALL verify the "Highlighted Presentations" section exists and contains talks
7. WHEN tests run THEN the system SHALL verify talk metadata (conference, date, video status) is properly formatted

### Requirement 4

**User Story:** As a site maintainer, I want to understand why production differs from local builds, so that I can prevent similar issues in the future.

#### Acceptance Criteria

1. WHEN investigating build differences THEN the system SHALL document the root cause of content rendering failures
2. WHEN investigating build differences THEN the system SHALL document why sample-talk.md appears on production
3. WHEN investigating build differences THEN the system SHALL document any configuration differences between local and production builds
4. WHEN investigating build differences THEN the system SHALL document the Jekyll version and plugin differences if any
5. WHEN fixes are implemented THEN the system SHALL include documentation explaining the changes and prevention strategies
