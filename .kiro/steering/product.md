# Product Overview

Conference Talk Show Notes is a Jekyll-based static site generator that creates mobile-optimized conference talk pages with automatic resource management and QR code accessibility. It solves the problem of sharing talk resources during and after presentations by providing a fast, mobile-friendly platform optimized for conference WiFi conditions.

**Key Differentiators:**
- Zero-dependency deployment via GitHub Pages
- Automated migration from Notist platform
- Mobile-first design for conference attendees
- Integrated Google Drive hosting for slides

## Purpose & Value

**Problem:** Conference speakers need an easy way to share slides, videos, and resources with attendees during presentations, but existing platforms are slow, require accounts, or don't work well on conference WiFi.

**Solution:** A static site generator that creates fast, mobile-optimized pages that can be shared via QR codes and work reliably on any network.

**Benefits:**
- Attendees can access resources immediately without accounts or downloads
- Speakers maintain full control over their content and presentation
- Fast page loads even on slow conference WiFi
- Professional portfolio of all presentations in one place
- Easy migration from existing Notist content

## Features

- **Mobile-First Design**: Optimized layouts and performance for mobile devices on conference networks
- **Automated Migration**: Import existing talks from Notist with slides, thumbnails, and resources automatically
- **Google Drive Integration**: Host slides on Google Drive with automatic embedding and access control
- **Thumbnail Management**: Automatic thumbnail generation and local storage with fallback images
- **Zero-Dependency Deployment**: Deploy to GitHub Pages without external services or databases
- **SEO Optimization**: Structured data and meta tags for discoverability
- **Security**: XSS protection, safe YAML parsing, and secure credential management
- **Accessibility**: WCAG-compliant markup and semantic HTML

## Target Users

**Primary Users:** Conference speakers who want to:
- Share talk resources easily during presentations via QR codes
- Migrate existing talks from Notist to a self-hosted platform
- Maintain a professional portfolio of presentations
- Provide accessible, mobile-friendly content to attendees
- Control their content without platform lock-in

## User Workflows

### Quick Start Workflow

**When to use:** You're new to the project and want to get a site running quickly with manual talk creation.

**Prerequisites:**
- Ruby 3.4+ installed
- Git installed
- GitHub account (for deployment)
- Basic familiarity with markdown and command line

**Steps:**

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/shownotes.git
   cd shownotes
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```
   Expected: Bundler installs all gems successfully. See [Troubleshooting](tech.md#troubleshooting) if bundle install fails.

3. **Configure speaker profile**
   - Edit `_config.yml`
   - Update `speaker:` section with your name, bio, social links
   - Update `title:`, `url:`, and `baseurl:` for your site

4. **Create your first talk**
   - Create a file in `_talks/` following the naming pattern: `YYYY-MM-DD-conference-talk-title.md`
   - See [Talk File Structure](structure.md#talk-file-structure) for format details
   - Add frontmatter: `layout: talk`
   - Add talk content using markdown

5. **Test locally**
   ```bash
   bundle exec jekyll serve --livereload
   ```
   Expected: Server starts on http://localhost:4000, opens in browser, shows your talk.

6. **Deploy to GitHub Pages**
   - Push to GitHub
   - Enable GitHub Pages in repository settings
   - Select source: main branch, root directory
   - Site will be available at `https://your-username.github.io/shownotes/`

**Expected Outcomes:**
- Working local development environment
- Site with speaker profile and at least one talk
- Live site on GitHub Pages

**Common Issues:**
- **Bundle install fails**: See [Dependency Issues](tech.md#dependency-issues)
- **Jekyll serve fails**: Check Ruby version with `ruby -v`, should be 3.4+
- **GitHub Pages not updating**: Check Actions tab for build errors
- **Styles not loading**: Verify `baseurl` in `_config.yml` matches repository name

### Migration Workflow

**When to use:** You have existing talks on Notist and want to import them automatically with slides, thumbnails, and resources.

**Prerequisites:**
- Completed Quick Start workflow
- Google Cloud project with Drive and Slides APIs enabled
- Service account credentials (`Google API.json` file)
- Notist profile URL

**Steps:**

1. **Set up Google API credentials**
   - Create Google Cloud project
   - Enable Google Drive API and Google Slides API
   - Create service account and download JSON key
   - Save as `Google API.json` in project root
   - Add to `.gitignore` (already configured)
   - See [Credentials Management](tech.md#credentials-management) for details

2. **Migrate a single talk (recommended first)**
   ```bash
   ruby migrate_talk.rb https://noti.st/speaker/talk-slug
   ```
   Expected: Script downloads talk content, uploads slides to Google Drive, downloads thumbnail, creates markdown file in `_talks/`, runs tests.

3. **Review migrated content**
   - Check `_talks/` for new markdown file
   - Check `assets/images/thumbnails/` for thumbnail
   - Verify Google Drive for uploaded slides
   - Test locally: `bundle exec jekyll serve --livereload`

4. **Migrate all talks (after successful single talk)**
   ```bash
   ruby migrate_talk.rb --speaker https://noti.st/speaker
   ```
   Expected: Script processes all talks sequentially, showing progress for each.

5. **Validate migration**
   ```bash
   bundle exec rake test:migration
   ```
   Expected: All migration tests pass, confirming content quality.

6. **Deploy updated site**
   ```bash
   git add _talks/ assets/images/thumbnails/
   git commit -m "Migrate talks from Notist"
   git push
   ```

**Expected Outcomes:**
- All Notist talks migrated to markdown files
- Slides hosted on Google Drive with proper permissions
- Thumbnails downloaded and stored locally
- All tests passing
- Live site updated with migrated content

**Common Issues:**
- **Authentication fails**: Verify `Google API.json` is valid and APIs are enabled
- **Slides upload fails**: Check service account has Drive access, see [Migration Issues](tech.md#migration-issues)
- **Thumbnail download fails**: Notist may block automated downloads, add manually
- **Tests fail after migration**: Review test output, may need content adjustments
- **Migration is slow**: Use `--skip-tests` flag for faster migration, run tests separately

**Decision Points:**
- **Migrate one vs all**: Start with one talk to verify setup, then migrate all
- **Skip tests**: Use `--skip-tests` for faster migration if you'll run tests separately
- **Google Drive vs local**: Google Drive provides hosting and embedding, local requires manual upload

### Manual Creation Workflow

**When to use:** You want to create talks manually without migration, or you're adding a new talk after initial setup.

**Prerequisites:**
- Completed Quick Start workflow
- Talk content ready (title, date, conference, abstract, resources)
- Optional: Slides URL, video URL, thumbnail image

**Steps:**

1. **Create talk file**
   - Create file in `_talks/` with naming pattern: `YYYY-MM-DD-conference-talk-title.md`
   - Use lowercase, hyphens for spaces, date prefix for chronological sorting
   - Example: `2025-10-01-devconf-coding-fast.md`

2. **Add frontmatter**
   ```markdown
   ---
   layout: talk
   ---
   ```
   Note: Minimal frontmatter is intentional, content is in markdown body.

3. **Add talk content**
   ```markdown
   # Talk Title

   **Conference:** Conference Name YYYY  
   **Date:** YYYY-MM-DD  
   **Slides:** [View Slides](URL)  
   **Video:** [Watch Video](URL)  

   A presentation at Conference Name in Month YYYY about [topic]...

   ## Abstract

   Detailed description of the talk...

   ## Resources

   - [Resource Name](URL)
   - [Another Resource](URL)
   ```
   See [Talk File Structure](structure.md#talk-file-structure) for complete format.

4. **Add thumbnail (optional but recommended)**
   - Save thumbnail image as `{talk-slug}-thumbnail.png` in `assets/images/thumbnails/`
   - Recommended size: ~400x300px
   - Format: PNG or JPG
   - Fallback: `placeholder-thumbnail.svg` used if missing

5. **Test locally**
   ```bash
   bundle exec jekyll serve --livereload
   ```
   Expected: Talk appears in list, individual page renders correctly, thumbnail displays.

6. **Validate content**
   ```bash
   bundle exec rake test:integration
   ```
   Expected: Content validation tests pass, confirming proper format.

7. **Deploy**
   ```bash
   git add _talks/ assets/images/thumbnails/
   git commit -m "Add talk: [talk title]"
   git push
   ```

**Expected Outcomes:**
- New talk file in `_talks/` with proper format
- Thumbnail in `assets/images/thumbnails/` (or using fallback)
- Talk appears on site with correct rendering
- All validation tests pass

**Best Practices:**
- Use consistent date format (YYYY-MM-DD) for sorting
- Include conference name and year in filename for clarity
- Add abstract for SEO and discoverability
- Link to slides and video when available
- Use descriptive resource names, not just "Link"
- Test locally before deploying

**Common Issues:**
- **Talk doesn't appear**: Check frontmatter has `layout: talk`, check filename format
- **Thumbnail not showing**: Verify filename matches talk slug exactly, check file extension
- **Formatting issues**: Ensure proper markdown syntax, check for special characters
- **Links broken**: Use full URLs including https://, test all links

### Deployment Workflow

**When to use:** You're ready to deploy your site to production for public access.

**Option 1: GitHub Pages (Recommended)**

**When to use:** You want zero-configuration hosting with automatic builds.

**Prerequisites:**
- GitHub repository with your site
- Repository is public (or GitHub Pro for private repos)

**Steps:**

1. **Configure site URL**
   - Edit `_config.yml`
   - Set `url: "https://your-username.github.io"`
   - Set `baseurl: "/repository-name"` (or `""` if using custom domain)

2. **Enable GitHub Pages**
   - Go to repository Settings → Pages
   - Source: Deploy from branch
   - Branch: main, folder: / (root)
   - Save

3. **Verify deployment**
   - Wait 1-2 minutes for initial build
   - Visit `https://your-username.github.io/repository-name/`
   - Check Actions tab for build status

4. **Optional: Custom domain**
   - Add `CNAME` file with your domain
   - Configure DNS with your domain provider
   - Enable HTTPS in GitHub Pages settings

**Expected Outcomes:**
- Site live at GitHub Pages URL
- Automatic rebuilds on every push
- HTTPS enabled by default
- Optional custom domain configured

**Common Issues:**
- **404 errors**: Check `baseurl` matches repository name exactly
- **Styles not loading**: Verify `url` and `baseurl` in `_config.yml`
- **Build fails**: Check Actions tab for errors, usually Jekyll build issues
- **Custom domain not working**: Verify DNS settings, allow 24-48 hours for propagation

**Option 2: Custom Hosting**

**When to use:** You want full control over hosting, need custom server configuration, or want to use your own infrastructure.

**Prerequisites:**
- Web server (Apache, Nginx, etc.)
- SSH access to server
- Domain name (optional)

**Steps:**

1. **Build site locally**
   ```bash
   bundle exec jekyll build
   ```
   Expected: Site generated in `_site/` directory.

2. **Configure for production**
   - Edit `_config.yml`
   - Set `url: "https://yourdomain.com"`
   - Set `baseurl: ""` (or subdirectory if needed)
   - Rebuild: `bundle exec jekyll build`

3. **Upload to server**
   ```bash
   rsync -avz _site/ user@server:/var/www/html/
   ```
   Or use FTP, SCP, or your hosting provider's upload method.

4. **Configure web server**
   - Point document root to uploaded files
   - Enable HTTPS (Let's Encrypt recommended)
   - Configure redirects if needed

5. **Verify deployment**
   - Visit your domain
   - Test all pages and links
   - Verify HTTPS is working

**Expected Outcomes:**
- Site live on custom domain
- Full control over server configuration
- Manual rebuild and upload process

**Common Issues:**
- **Paths broken**: Check `url` and `baseurl` configuration
- **Permissions errors**: Ensure web server can read all files
- **HTTPS not working**: Configure SSL certificate, check server configuration

## Decision Guides

### Migration vs Manual Creation

**Use Migration when:**
- You have existing talks on Notist
- You want to preserve slides, thumbnails, and resources automatically
- You have many talks to import
- You want Google Drive hosting for slides

**Use Manual Creation when:**
- You're creating new talks not on Notist
- You want full control over content format
- You don't need Google Drive integration
- You're adding one-off talks to existing site

### Google Drive vs Local Hosting

**Use Google Drive when:**
- You want automatic slide embedding
- You need access control for slides
- You want to update slides without redeploying site
- You're using the migration workflow

**Use Local Hosting when:**
- You want complete control over files
- You don't want external dependencies
- You have static slide PDFs or images
- You prefer simpler deployment

### Performance vs Convenience

**Fast Build (Development):**
- Use `bundle exec jekyll serve --livereload` for instant feedback
- Use `bundle exec rake quick` for essential tests only
- Use `--skip-tests` flag during migration

**Thorough Build (Production):**
- Use `bundle exec jekyll build` for production builds
- Use `bundle exec rake test` for full test suite
- Run migration with tests enabled for validation

See [Performance](tech.md#performance) for detailed optimization guidance.
