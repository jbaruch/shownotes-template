# Migration Test Scenarios

## Overview

Test scenarios specifically for **per-page migration validation** from noti.st to Jekyll. This focuses on content migration quality and per-page functionality, not infrastructure setup.

## Infrastructure vs Migration Testing

**Infrastructure (one-time setup - already fixed):**
- CSP configuration in `_layouts/default.html`
- Liquid template syntax fixes
- Google Drive thumbnail URL pattern implementation
- CSS styling for hover effects and badges

**Migration (per-page validation - this document):**
- Content accuracy and completeness
- Resource type detection and formatting  
- URL validation and accessibility
- Visual quality and functionality

## Test Suite 1: Content Migration Accuracy

### Test 1.1: Complete Resource Migration
**Priority**: Critical 🚨

```gherkin
Feature: Complete resource migration
  As a content migrator
  I want to ensure ALL resources are migrated
  So that no content is lost in the migration process

Scenario: All resources from source are migrated
  Given a noti.st talk page with N resources in the Resources section
  When I migrate the talk to Jekyll
  Then the Jekyll talk should have exactly N resources
  And each resource should have correct type, title, URL, and description
  And no resources should be missing or duplicated
  And the total count should match exactly: N source = N migrated

Scenario: Resource count validation
  Given the original noti.st page shows "40 Resources"
  When migration is complete
  Then Jekyll resources array should have length 40
  And each resource should be properly formatted with required fields
```

### Test 1.2: Resource Type Detection
**Priority**: High 

```gherkin
Scenario: Correct resource type assignment
  Given resources of different types (slides, video, PDF, links)
  When I migrate the talk
  Then Google Slides URLs should be marked as type "slides"
  And YouTube URLs should be marked as type "video" 
  And Google Drive PDF URLs should be marked as type "slides"
  And other external links should be marked as type "link"
  And each type should render with appropriate preview behavior
```

### Test 1.3: Video Detection Accuracy
**Priority**: High 

```gherkin
Scenario: Video presence is correctly detected
  Given a talk page with embedded YouTube video
  When I analyze the page for video resources
  Then I should correctly identify the presence of video
  And extract the correct YouTube URL (https://youtube.com/watch?v=...)
  And not claim "no video" when video exists
  And video should appear in resources list with type "video"
```

##  Test Suite 2: Resource URL Validation

### Test 2.1: Google Slides URL Format
**Priority**: Critical 🚨

```gherkin
Scenario: Google Slides URLs use correct format for thumbnails
  Given a talk with Google Slides presentation
  When I inspect the slides resource URL
  Then it should use /d/{document_id}/edit format
  And not use /d/e/{published_id}/pub format  
  And should be accessible for thumbnail generation
  And should generate working thumbnail: https://lh3.googleusercontent.com/d/{id}=s400
```

### Test 2.2: External Link Accessibility  
**Priority**: High 

```gherkin
Scenario: All migrated resource URLs work
  Given migrated talks with external resource links
  When I test each resource URL
  Then all links should return successful HTTP responses (200-299)
  And should point to the intended resources
  And should not be broken, expired, or malformed
  And Google Drive/Slides URLs should be viewable
```

##  Test Suite 3: Visual Quality Validation

### Test 3.1: Thumbnail Display Quality
**Priority**: Critical 🚨

```gherkin
Scenario: Real content thumbnails are displayed  
  Given a migrated talk with slides/PDF resources
  When I view the homepage preview
  Then I should see actual content as thumbnail image
  And not see broken image icons or placeholder graphics
  And thumbnail should visually match first slide/page content  
  And images should load within reasonable time (5 seconds)
```

### Test 3.2: Resource Preview Functionality
**Priority**: High 

```gherkin
Scenario: Resource previews work correctly
  Given different resource types in a migrated talk
  When I view the talk page
  Then PDF resources should show Google Drive thumbnails
  And Google Slides should show slide content thumbnails
  And video resources should show YouTube thumbnails with play overlay
  And all previews should be clickable and functional
```

##  Test Suite 4: Migration Quality Assurance

### Test 4.1: Content Completeness Check
**Priority**: Critical 🚨

```gherkin
Scenario: No content loss during migration
  Given the original noti.st page and migrated Jekyll page
  When I compare them side by side
  Then all key information should be present (title, description, resources)
  And visual quality should match or exceed original
  And no functionality should be lost or degraded
  And user experience should be consistent or better
```

### Test 4.2: Link and Resource Functionality
**Priority**: High 

```gherkin
Scenario: All migrated resources are functional
  Given a fully migrated talk page
  When I test each resource (slides, videos, PDFs, links)
  Then all external links should work correctly
  And embedded content should display properly
  And download links should provide correct files
  And video embeds should play without errors
```

##  Per-Page Migration Checklist

### Step 1: Pre-Migration Analysis
- [ ] Count total resources on source noti.st page (N resources)
- [ ] Identify all resource types (slides, videos, PDFs, links)
- [ ] Check video presence and extract YouTube URLs
- [ ] Validate all source URLs are currently accessible

### Step 2: Content Migration
- [ ] Copy ALL N resources to Jekyll YAML (no shortcuts!)
- [ ] Assign correct resource types based on URLs
- [ ] Convert Google Slides to shared document format (/d/{id}/edit)
- [ ] Preserve all titles, descriptions, and metadata

### Step 3: Post-Migration Validation  
- [ ] **Critical**: Verify resource count matches exactly (N source = N migrated)
- [ ] Test all thumbnails display real content (no broken images)
- [ ] Validate all external links are clickable and functional
- [ ] Check Google Slides URLs generate working thumbnails
- [ ] Confirm video embeds work properly

### Step 4: Quality Check
- [ ] Side-by-side comparison: original vs migrated page
- [ ] Confirm no content loss or functionality degradation
- [ ] Test user workflows (browsing, clicking resources)
- [ ] Visual quality matches or exceeds original

## 🚨 Migration Success Criteria

**A PAGE MIGRATION IS COMPLETE ONLY WHEN:**

 **All resources migrated** (count matches exactly: N source = N migrated)  
 **All thumbnails working** (no broken images or placeholders)  
 **All links functional** (external URLs return 200, no 404s)  
 **Content accuracy** (titles, descriptions, metadata preserved)  
 **Visual quality** (matches or exceeds original appearance)  
 **Functionality preserved** (videos play, downloads work, previews show)

**If ANY criterion fails, the page migration is NOT complete.**

---

##  Migration vs Infrastructure

**Use this document for**: Content migration validation (per talk page)  
**Not for**: Site-wide infrastructure, CSS, CSP, templates (those are one-time setup)