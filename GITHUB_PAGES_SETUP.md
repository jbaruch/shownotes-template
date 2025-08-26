# GitHub Pages Setup Instructions

## Issue
The Deploy workflow is failing with "Resource not accessible by integration" error because GitHub Pages has never been enabled for this repository. The "Pages" option doesn't appear in Settings until Pages is enabled for the first time.

## Required Manual Configuration

### Step 1: Enable GitHub Pages Initially
Since the "Pages" option is missing, you need to enable it first by creating a simple `index.html` file:

1. Go to your repository on GitHub
2. Click "Add file" → "Create new file" 
3. Name it `index.html`
4. Add simple content:
   ```html
   <!DOCTYPE html>
   <html>
   <head><title>Shownotes</title></head>
   <body><h1>Shownotes Site</h1></body>
   </html>
   ```
5. Commit directly to the main branch
6. Wait 1-2 minutes for GitHub to detect the HTML file

### Step 2: Navigate to Repository Settings
1. Go to your repository on GitHub
2. Click on the "Settings" tab  
3. In the left sidebar, look for "Pages" (should now appear)

### Step 3: Configure Publishing Source  
1. Under "Build and deployment", find the "Source" dropdown
2. Select **"GitHub Actions"** instead of "Deploy from a branch"
3. Click "Save"

### Step 3: Verify Environment Creation
After selecting GitHub Actions, GitHub will automatically:
- Create a new environment called "github-pages"
- Add protection rules restricting deployment to the main branch
- Enable the necessary OIDC permissions

## Updated Workflow Changes
The deploy.yml workflow has been updated with:
- Latest action versions (configure-pages@v5, upload-pages-artifact@v4, deploy-pages@v5)
- Improved error handling and explicit token configuration
- Better documentation

## Expected Behavior After Setup
Once configured, pushes to the main branch will:
1. Run the CI tests successfully ✅
2. Build the Jekyll site ✅  
3. Deploy to GitHub Pages ✅
4. Make the site available at your Pages URL

## Troubleshooting
If you continue to see permission errors:
1. Verify the repository has GitHub Pages enabled
2. Check that the Pages source is set to "GitHub Actions"
3. Ensure the workflow permissions include `pages: write` and `id-token: write`

The deployment workflow will work once GitHub Pages is properly configured in the repository settings.