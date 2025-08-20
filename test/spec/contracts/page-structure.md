# Page Structure Contract - MVP Shownotes Page

## Overview
Defines the expected structure and content contracts for the MVP shownotes page implementation.

## Page Structure Requirements

### HTML Document Structure
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <!-- Meta tags for mobile responsiveness -->
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <!-- SEO and social sharing meta tags -->
  <meta property="og:title" content="[Talk Title]">
  <meta property="og:description" content="[Talk Description]">
  <meta property="og:type" content="article">
  
  <title>[Talk Title] - [Speaker Name] - [Conference Name]</title>
</head>
<body>
  <!-- Main content structure defined below -->
</body>
</html>
```

### Required Page Sections

#### 1. Header Section
- **Talk Title**: Main heading (h1)
- **Speaker Name**: Prominently displayed
- **Conference Details**: Conference name, date, location
- **Talk Status**: Upcoming, In Progress, or Completed

#### 2. Talk Description Section
- **Brief Description**: 1-2 paragraph summary
- **Talk Abstract**: If available, expandable/collapsible
- **Topics Covered**: Key topics or tags

#### 3. Resources Section
- **Slides**: Direct link to presentation slides
- **Code Repository**: GitHub/GitLab repository links
- **Demo Links**: Live demos or interactive examples
- **Reference Links**: Additional resources mentioned in talk
- **Video**: Placeholder for future video content

#### 4. Footer Section
- **Notification Signup**: Placeholder for Phase 3 implementation
- **Contact/Social**: Speaker contact information
- **Share Options**: Basic social sharing capabilities

## Content Data Contract

### Required Frontmatter (YAML)
```yaml
---
layout: talk
title: "Talk Title Here"
speaker: "Speaker Name"
conference: "Conference Name"
date: "YYYY-MM-DD"
location: "Conference Location"
status: "upcoming|completed|in-progress"
description: "Brief talk description for meta tags and display"
topics:
  - "Topic 1"
  - "Topic 2"
resources:
  slides:
    title: "Presentation Slides"
    url: "https://example.com/slides"
    type: "slides"
  code:
    title: "Demo Code Repository"
    url: "https://github.com/user/repo"
    type: "repository"
  links:
    - title: "Reference Article"
      url: "https://example.com/article"
      description: "Detailed explanation of concept X"
social:
  twitter: "@speaker"
  github: "speaker"
  website: "https://speaker.example.com"
---
```

### Optional Frontmatter Fields
```yaml
abstract: "Longer, detailed abstract of the talk content"
duration: "45 minutes"
level: "beginner|intermediate|advanced"
tags: 
  - "javascript"
  - "web-development"
video:
  available: false
  url: ""
  platform: "youtube|vimeo"
slides_embed: "https://slides.example.com/embed/123"
```

## URL Structure Contract

### Page URLs
- **Format**: `/talks/[conference-slug]/[talk-slug]/`
- **Example**: `/talks/jsconf-2024/modern-javascript-patterns/`
- **Constraints**: 
  - Lowercase, hyphen-separated
  - No special characters
  - SEO-friendly
  - Shareable and memorable

### Asset URLs
- **Slides**: Can be external URLs or relative paths
- **Code**: Typically external repository URLs
- **Images**: Relative paths under `/assets/images/talks/`

## Responsive Design Contract

### Breakpoints
- **Mobile**: < 768px
- **Tablet**: 768px - 1024px  
- **Desktop**: > 1024px

### Mobile-First Requirements
- Touch-friendly buttons (minimum 44px)
- Readable text without zooming
- Accessible navigation
- Fast loading on slower connections

## Accessibility Contract

### Required Standards
- **WCAG 2.1 AA compliance**
- **Semantic HTML structure**
- **Proper heading hierarchy** (h1 → h2 → h3)
- **Alt text for images**
- **Keyboard navigation support**
- **Screen reader compatibility**

### Color and Contrast
- **Minimum contrast ratio**: 4.5:1 for normal text
- **Large text contrast**: 3:1 for text 18pt+ or 14pt+ bold
- **Interactive elements**: Clear focus indicators

## Performance Contract

### Loading Requirements
- **First Contentful Paint**: < 3 seconds on 3G
- **Largest Contentful Paint**: < 5 seconds on 3G
- **Cumulative Layout Shift**: < 0.1

### Optimization Requirements
- **Minified CSS and JavaScript**
- **Optimized images** (WebP where supported)
- **Minimal external dependencies**
- **Efficient Jekyll build process**

## Browser Support Contract

### Required Support
- **Mobile Safari**: iOS 12+
- **Chrome Mobile**: Android 8+
- **Desktop Chrome**: Latest 2 versions
- **Desktop Safari**: macOS 10.14+
- **Desktop Firefox**: Latest 2 versions
- **Edge**: Chromium-based versions

### Progressive Enhancement
- **Core functionality without JavaScript**
- **Enhanced experience with JavaScript**
- **Graceful degradation for older browsers**