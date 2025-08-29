# Migration Workflow: noti.st → Jekyll

## Step-by-Step Process

### 1. Extract Talk Metadata
From `https://speaking.jbaru.ch/TALK_ID`:
- Talk title, conference, date, description
- Speaker information (Baruch Sadogursky)

### 2. Extract PDF Slides
From noti.st presentation page:
- Find PDF download link: `https://on.notist.cloud/pdf/deck-*.pdf`
- Download the PDF file locally
- Upload to Google Drive
- Get shareable link: `https://drive.google.com/file/d/FILE_ID/view`

### 3. Extract YouTube Videos
From noti.st presentation page:
- Look for embedded YouTube players
- Extract YouTube video ID from iframe src or embed URLs
- Format as: `https://youtube.com/watch?v=VIDEO_ID`

### 4. Create Jekyll Markdown File
Template structure:
```yaml
---
layout: talk
title: "Presentation Title"
speaker: "Baruch Sadogursky"
conference: "Conference Name YYYY"
date: "YYYY-MM-DD"
status: "completed"
description: "Brief description"
abstract: |
  Multi-line abstract content
resources:
  - type: "slides"
    title: "Presentation Slides (XX slides)"
    url: "https://drive.google.com/file/d/FILE_ID/view"
    description: "Complete slide deck"
  - type: "video"
    title: "Presentation Video"
    url: "https://youtube.com/watch?v=VIDEO_ID"
    description: "Full presentation recording"
---

## Key Takeaways
[Content here]
```

### 5. File Naming Convention
`YYYY-MM-DD-conference-slug-title.md`

Example: `2025-06-20-voxxed-luxembourg-technical-enshittification.md`

## Current Migration Status

### ✅ Completed Infrastructure
- Jekyll collection configured (`_talks/`)
- Embedding system supports:
  - Google Drive PDF previews
  - YouTube video embeds
  - Google Slides embeds
- Ordering: newest-first (by date)
- Homepage preview system working

### 🔄 Migration Process Required
1. **PDF Processing**: 
   - Download from noti.st: `https://on.notist.cloud/pdf/deck-2b48ce35fd8657d3.pdf`
   - Upload to Google Drive
   - Get embed URL

2. **Video Processing**:
   - Extract YouTube URLs from noti.st embed code
   - Verify video accessibility

3. **Content Creation**:
   - Generate Jekyll markdown files
   - Test embedding functionality
   - Verify ordering and display

## Example: Technical Enshittification Talk

**Source Data**:
- Noti.st: `https://speaking.jbaru.ch/V8R94I`
- PDF: `https://on.notist.cloud/pdf/deck-2b48ce35fd8657d3.pdf`
- Video: [Need to extract from page]

**Target Result**: Fully embedded slides and video on detail page, with preview on homepage.