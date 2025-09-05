# Advanced Features

Advanced customization, deployment, and troubleshooting for the Conference Talk Show Notes platform.

## Customization

### Theme Customization

#### CSS Modifications

Edit `assets/css/style.css` to customize appearance:

```css
/* Custom color scheme */
:root {
  --primary-color: #your-brand-color;
  --secondary-color: #your-accent-color;
  --text-color: #333;
  --background-color: #fff;
}

/* Custom fonts */
body {
  font-family: 'Your-Font', -apple-system, BlinkMacSystemFont, sans-serif;
}

/* Custom layout */
.talk-list-item {
  border: 2px solid var(--primary-color);
  border-radius: 8px;
}
```

#### Layout Modifications

Create custom layouts in `_layouts/`:

```html
<!-- _layouts/custom-talk.html -->
---
layout: default
---

<article class="custom-talk">
  <header class="custom-header">
    <h1>{{ page.title }}</h1>
    <!-- Your custom header content -->
  </header>
  
  <div class="custom-content">
    {{ content }}
  </div>
  
  <footer class="custom-footer">
    <!-- Your custom footer -->
  </footer>
</article>
```

Use in talk frontmatter:
```yaml
---
layout: custom-talk
---
```

### Logo and Branding

#### Add Custom Logo

1. Add logo to `assets/images/logo.png`
2. Edit `_layouts/default.html`:

```html
<header class="site-header">
  <img src="{{ '/assets/images/logo.png' | relative_url }}" alt="Logo" class="site-logo">
  <h1>{{ site.title }}</h1>
</header>
```

#### Favicon

Add favicon files to root directory:
- `favicon.ico`
- `favicon-16x16.png`
- `favicon-32x32.png`
- `apple-touch-icon.png`

Update `_layouts/default.html`:
```html
<head>
  <link rel="icon" type="image/x-icon" href="/favicon.ico">
  <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
  <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">
</head>
```

### Analytics Integration

#### Google Analytics

Add to `_config.yml`:
```yaml
google_analytics: YOUR-GA-TRACKING-ID
```

Add tracking code to `_includes/analytics.html`:
```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id={{ site.google_analytics }}"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', '{{ site.google_analytics }}');
</script>
```

Include in `_layouts/default.html`:
```html
{% if site.google_analytics %}
  {% include analytics.html %}
{% endif %}
```

## Deployment

### GitHub Pages

#### Setup

1. **Create repository** on GitHub
2. **Push code**:
   ```bash
   git remote add origin https://github.com/username/shownotes.git
   git push -u origin main
   ```

3. **Enable GitHub Pages**:
   - Go to repository Settings
   - Scroll to "Pages" section
   - Source: "Deploy from a branch"
   - Branch: `main` / `root`

4. **Configure site URL** in `_config.yml`:
   ```yaml
   url: "https://username.github.io"
   baseurl: "/shownotes"  # If not using custom domain
   ```

#### Custom Domain

1. **Add CNAME file** to repository root:
   ```
   yourdomain.com
   ```

2. **Configure DNS** with your domain provider:
   ```
   CNAME    www    username.github.io
   A        @      185.199.108.153
   A        @      185.199.109.153
   A        @      185.199.110.153
   A        @      185.199.111.153
   ```

3. **Update `_config.yml`**:
   ```yaml
   url: "https://yourdomain.com"
   baseurl: ""
   ```

### Netlify

#### Automatic Deployment

1. **Connect repository** on Netlify
2. **Build settings**:
   - Build command: `bundle exec jekyll build`
   - Publish directory: `_site`
   - Ruby version: 3.4.5

3. **Environment variables**:
   ```
   RUBY_VERSION=3.4.5
   JEKYLL_ENV=production
   ```

#### Custom Domain

1. **Add domain** in Netlify dashboard
2. **Configure DNS** to point to Netlify:
   ```
   CNAME    www    your-site.netlify.app
   ```

### Vercel

#### Deploy Configuration

Create `vercel.json`:
```json
{
  "buildCommand": "bundle install && bundle exec jekyll build",
  "outputDirectory": "_site",
  "framework": "jekyll"
}
```

## Advanced Configuration

### Multiple Speaker Support

For sites with multiple speakers, modify `_config.yml`:

```yaml
speakers:
  speaker1:
    name: "Speaker One"
    bio: "Bio for speaker one..."
    social:
      github: "speaker1"
  speaker2:
    name: "Speaker Two"
    bio: "Bio for speaker two..."
    social:
      github: "speaker2"

# Default speaker
default_speaker: speaker1
```

Use in talk frontmatter:
```yaml
---
layout: talk
speaker: speaker2
---
```

### Content Collections

#### Additional Collections

Add to `_config.yml`:
```yaml
collections:
  talks:
    output: true
    permalink: /:name/
  workshops:
    output: true
    permalink: /workshops/:name/
  articles:
    output: true
    permalink: /articles/:name/
```

Create directories:
- `_workshops/`
- `_articles/`

### Search Functionality

#### Simple Search

Add to `assets/js/search.js`:
```javascript
// Simple client-side search
function searchTalks() {
  const query = document.getElementById('search').value.toLowerCase();
  const talks = document.querySelectorAll('.talk-item');
  
  talks.forEach(talk => {
    const text = talk.textContent.toLowerCase();
    talk.style.display = text.includes(query) ? 'block' : 'none';
  });
}
```

Add search form to layout:
```html
<input type="text" id="search" placeholder="Search talks..." onkeyup="searchTalks()">
```

## Performance Optimization

### Image Optimization

#### Responsive Images

```html
<!-- _includes/responsive-image.html -->
<picture>
  <source media="(min-width: 800px)" 
          srcset="{{ include.src | replace: '.png', '-large.png' }}">
  <source media="(min-width: 400px)" 
          srcset="{{ include.src | replace: '.png', '-medium.png' }}">
  <img src="{{ include.src | replace: '.png', '-small.png' }}" 
       alt="{{ include.alt }}" 
       loading="lazy">
</picture>
```

#### Thumbnail Optimization

```bash
# Generate multiple sizes for existing thumbnails
for img in assets/images/thumbnails/*.png; do
  convert "$img" -resize 400x300 "${img%-thumbnail.png}-thumbnail-large.png"
  convert "$img" -resize 200x150 "${img%-thumbnail.png}-thumbnail-small.png"
done
```

### Caching

#### Browser Caching

Configure Jekyll for better caching:

```yaml
# _config.yml
sass:
  sourcemap: never
  style: compressed

# Enable compression
plugins:
  - jekyll-feed
  - jekyll-sitemap  
  - jekyll-seo-tag
```

## Monitoring and Analytics

### Performance Monitoring

For production sites, you may want to add performance monitoring. This requires additional setup and isn't included by default.

#### Basic Performance Metrics

You can add basic performance monitoring by creating custom JavaScript:

```html
<!-- _includes/performance.html -->
<script>
// Basic performance measurement
window.addEventListener('load', function() {
  const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
  console.log('Page load time:', loadTime + 'ms');
});
</script>
```

### Analytics Integration

#### Google Analytics

See the [Analytics Integration](#analytics-integration) section above for Google Analytics setup.

### Basic Error Monitoring

For basic error tracking, you can add simple error logging:

```html
<!-- _includes/error-tracking.html -->
<script>
window.addEventListener('error', function(e) {
  console.error('JavaScript error:', e.error);
  // Add your error reporting logic here
});
</script>
```

## Security

### Content Security Policy

Add to `_layouts/default.html`:
```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               img-src 'self' data: https:; 
               script-src 'self' 'unsafe-inline' https://www.google-analytics.com; 
               style-src 'self' 'unsafe-inline';">
```

### HTTPS Enforcement

#### Netlify
Add `_redirects` file:
```
# Force HTTPS
https://yourdomain.com/* https://yourdomain.com/:splat 301!
```

#### GitHub Pages
Automatically enforced with custom domains.

## Troubleshooting

### Build Issues

#### Jekyll Build Fails

```bash
# Clear cache and rebuild
bundle exec jekyll clean
bundle exec jekyll build --verbose --trace

# Check for plugin conflicts
bundle exec jekyll doctor

# Test locally
bundle exec jekyll serve --livereload
```

#### Deployment Fails

```bash
# Verify Gemfile.lock is included
git add Gemfile.lock
git commit -m "Add Gemfile.lock"

# Check Ruby version consistency
echo "ruby '3.4.5'" >> Gemfile

# Test production build locally
JEKYLL_ENV=production bundle exec jekyll build
```

### Performance Issues

#### Slow Build Times

```bash
# Profile build performance
bundle exec jekyll build --profile

# Exclude unnecessary files
echo "_site/" >> .gitignore
echo ".jekyll-cache/" >> .gitignore

# Use incremental builds
bundle exec jekyll serve --incremental
```

#### Large Site Size

```bash
# Analyze site size
du -sh _site/

# Optimize images
find assets/images -name "*.png" -exec optipng {} \;

# Compress CSS/JS manually
find assets -name "*.css" -exec gzip -9 {} \;

# Or use Jekyll's built-in compression
# Set in _config.yml: sass.style: compressed
```

### Content Issues

#### Links Not Working

```bash
# Test all links
bundle exec ruby test/impl/e2e/link_validation_test.rb

# Check base URL
grep baseurl _config.yml

# Verify relative URLs
grep -r "href=" _site/ | grep -v "http"
```

#### Missing Resources

```bash
# Validate resource accessibility
bundle exec ruby test/migration/migration_test.rb

# Check Google Drive permissions
bundle exec ruby test/external/google_drive_integration_test.rb
```

## Backup and Recovery

### Automated Backups

#### GitHub Actions Backup

Create `.github/workflows/backup.yml`:
```yaml
name: Backup
on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly backup

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Create backup
        run: |
          tar -czf backup-$(date +%Y%m%d).tar.gz _talks/ assets/ _config.yml
      - name: Upload to storage
        # Upload to your preferred backup service
```

### Recovery Procedures

#### Restore from Backup

```bash
# Restore talks
tar -xzf backup-20240101.tar.gz
git add _talks/ assets/
git commit -m "Restore from backup"

# Rebuild site
bundle exec jekyll build

# Verify integrity
bundle exec ruby test/run_tests.rb
```

## Next Steps

- **Monitor performance**: Set up analytics and monitoring
- **Scale content**: Add more talks and features  
- **Community**: Share your customizations
- **Contribute**: Help improve the platform

## Additional Resources

For more advanced integration and customization:

- Check the existing `utils/` directory for helper scripts
- Review the test suite in `test/` for examples of automation
- Examine `_layouts/` and `_includes/` for template customization
- Consider contributing improvements back to the project
