# Jekyll Integration Contract - MVP Implementation

## Overview
Defines the Jekyll-specific implementation contracts for the MVP shownotes platform.

## Jekyll Configuration Contract

### Required _config.yml Settings
```yaml
# Site settings
title: "Shownotes"
description: "Conference talk resources and show notes"
baseurl: ""
url: "https://username.github.io"

# Build settings
markdown: kramdown
highlighter: rouge
sass:
  sass_dir: _sass
  style: compressed

# Collections
collections:
  talks:
    output: true
    permalink: /talks/:path/

# Plugins
plugins:
  - jekyll-feed
  - jekyll-sitemap
  - jekyll-seo-tag

# Exclude from build
exclude:
  - Gemfile
  - Gemfile.lock
  - node_modules
  - README.md
  - test/

# GitHub Pages compatibility
github: [metadata]
```

### Required Directory Structure
```
/
├── _config.yml
├── _layouts/
│   ├── default.html
│   └── talk.html
├── _includes/
│   ├── head.html
│   ├── header.html
│   ├── footer.html
│   └── talk-resources.html
├── _sass/
│   ├── main.scss
│   ├── _base.scss
│   ├── _layout.scss
│   └── _talks.scss
├── _talks/
│   └── [talk-slug].md
├── assets/
│   ├── css/
│   │   └── main.scss
│   └── images/
├── index.md
└── talks.md
```

## Layout Contract

### default.html Layout
```html
<!DOCTYPE html>
<html lang="{{ page.lang | default: site.lang | default: 'en' }}">
  {% include head.html %}
  <body>
    {% include header.html %}
    <main class="page-content" aria-label="Content">
      <div class="wrapper">
        {{ content }}
      </div>
    </main>
    {% include footer.html %}
  </body>
</html>
```

### talk.html Layout
```html
---
layout: default
---
<article class="talk">
  <header class="talk-header">
    <h1 class="talk-title">{{ page.title }}</h1>
    <div class="talk-meta">
      <span class="speaker">{{ page.speaker }}</span>
      <span class="conference">{{ page.conference }}</span>
      <time class="date">{{ page.date | date: "%B %d, %Y" }}</time>
      <span class="status status-{{ page.status }}">{{ page.status | capitalize }}</span>
    </div>
  </header>

  <div class="talk-content">
    {% if page.description %}
    <div class="talk-description">
      <p>{{ page.description }}</p>
    </div>
    {% endif %}

    {{ content }}

    {% if page.resources %}
    {% include talk-resources.html resources=page.resources %}
    {% endif %}
  </div>

  <footer class="talk-footer">
    {% if page.social %}
    <div class="speaker-social">
      <!-- Social links -->
    </div>
    {% endif %}
    
    <div class="talk-sharing">
      <!-- Share buttons -->
    </div>
  </footer>
</article>
```

## Include Templates Contract

### head.html
```html
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  
  <title>{% if page.title %}{{ page.title | escape }} - {{ site.title }}{% else %}{{ site.title }}{% endif %}</title>
  <meta name="description" content="{{ page.description | default: site.description | strip_html | normalize_whitespace | truncate: 160 | escape }}">
  
  <!-- Open Graph meta tags -->
  <meta property="og:title" content="{{ page.title | default: site.title }}">
  <meta property="og:description" content="{{ page.description | default: site.description }}">
  <meta property="og:type" content="{% if page.layout == 'talk' %}article{% else %}website{% endif %}">
  <meta property="og:url" content="{{ page.url | absolute_url }}">
  
  <link rel="stylesheet" href="{{ '/assets/css/main.css' | relative_url }}">
  <link rel="canonical" href="{{ page.url | replace:'index.html','' | absolute_url }}">
  
  {% seo %}
</head>
```

### talk-resources.html
```html
<section class="talk-resources">
  <h2>Resources</h2>
  
  {% if include.resources.slides %}
  <div class="resource-item resource-slides">
    <h3>{{ include.resources.slides.title | default: "Slides" }}</h3>
    <a href="{{ include.resources.slides.url }}" target="_blank" rel="noopener">
      View Slides
    </a>
  </div>
  {% endif %}
  
  {% if include.resources.code %}
  <div class="resource-item resource-code">
    <h3>{{ include.resources.code.title | default: "Code" }}</h3>
    <a href="{{ include.resources.code.url }}" target="_blank" rel="noopener">
      View Repository
    </a>
  </div>
  {% endif %}
  
  {% if include.resources.links %}
  <div class="resource-item resource-links">
    <h3>Additional Resources</h3>
    <ul>
    {% for link in include.resources.links %}
      <li>
        <a href="{{ link.url }}" target="_blank" rel="noopener">{{ link.title }}</a>
        {% if link.description %}<p>{{ link.description }}</p>{% endif %}
      </li>
    {% endfor %}
    </ul>
  </div>
  {% endif %}
</section>
```

## Content File Contract

### Talk File Structure (_talks/example-talk.md)
```markdown
---
layout: talk
title: "Modern JavaScript Patterns"
speaker: "Jane Developer"
conference: "JSConf 2024"
date: "2024-03-15"
location: "San Francisco, CA"
status: "completed"
description: "Exploring modern JavaScript patterns and best practices for scalable applications"
topics:
  - "JavaScript"
  - "ES6+"
  - "Design Patterns"
resources:
  slides:
    title: "Presentation Slides"
    url: "https://slides.example.com/modern-js-patterns"
  code:
    title: "Demo Repository"
    url: "https://github.com/jane/modern-js-demo"
  links:
    - title: "MDN JavaScript Guide"
      url: "https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide"
      description: "Comprehensive JavaScript reference"
social:
  twitter: "@janedev"
  github: "janedev"
  website: "https://janedev.example.com"
---

## Talk Abstract

This talk explores modern JavaScript patterns that help create maintainable and scalable applications. We'll cover:

- ES6+ features and their practical applications
- Functional programming concepts in JavaScript
- Module patterns and organization strategies
- Testing patterns for modern JavaScript applications

## Key Takeaways

- Understanding when and how to use modern JavaScript features
- Implementing clean, maintainable code patterns
- Building scalable application architectures
- Best practices for code organization and testing
```

## Build Process Contract

### GitHub Actions Workflow
```yaml
name: Build and Deploy
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.0
        bundler-cache: true
    
    - name: Build site
      run: bundle exec jekyll build
    
    - name: Deploy to GitHub Pages
      if: github.ref == 'refs/heads/main'
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./_site
```

### Required Gemfile
```ruby
source "https://rubygems.org"

gem "github-pages", group: :jekyll_plugins
gem "jekyll-feed", "~> 0.12"
gem "jekyll-sitemap"
gem "jekyll-seo-tag"

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.6"
end

# Windows and JRuby does not include zoneinfo files
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", "~> 1.2"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.1", :platforms => [:mingw, :x64_mingw, :mswin]
```

## CSS/SCSS Contract

### Main SCSS Structure
```scss
// assets/css/main.scss
---
---

@import "base";
@import "layout";
@import "talks";

// Mobile-first responsive design
@media (min-width: 768px) {
  // Tablet styles
}

@media (min-width: 1024px) {
  // Desktop styles
}
```

### Required CSS Classes
- `.talk` - Main talk container
- `.talk-header` - Talk metadata section
- `.talk-title` - Main heading
- `.talk-meta` - Speaker, conference, date info
- `.talk-content` - Main content area
- `.talk-resources` - Resources section
- `.resource-item` - Individual resource container
- `.talk-footer` - Footer with social/sharing
- `.status-completed`, `.status-upcoming`, `.status-in-progress` - Status indicators