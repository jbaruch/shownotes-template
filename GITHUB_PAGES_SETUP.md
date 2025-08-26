# GitHub Pages Setup Instructions

## Issue
The Deploy workflow is failing with "Resource not accessible by integration" error because GitHub Pages has never been enabled for this repository. The "Pages" option doesn't appear in Settings until Pages is enabled for the first time.

## Required Manual Configuration

### Step 1: Fix Workflow Permissions (CRITICAL)
The deployment is failing because GitHub Actions doesn't have write permissions:

1. Go to your repository on GitHub
2. Click on the "Settings" tab
3. In the left sidebar, click "Actions" → "General"
4. Scroll down to "Workflow permissions"
5. Select **"Read and write permissions"** (not "Read repository contents")
6. Click "Save"

### Step 2: Enable GitHub Pages
The `index.html` file should have triggered GitHub to show the Pages option:

1. Still in Settings, look for "Pages" in the left sidebar
2. If "Pages" doesn't appear, wait a few more minutes for GitHub to detect the HTML file
3. Click on "Pages" when it appears

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

## Step 4: Test the Fix
After completing the above steps:

1. Go to Actions tab in your repository
2. Manually trigger the "Deploy to GitHub Pages" workflow by clicking "Run workflow"
3. OR push a small change to trigger it automatically

## Expected Behavior After Setup
Once configured, pushes to the main branch will:
1. Run the CI tests successfully ✅
2. Build the Jekyll site ✅  
3. Deploy to GitHub Pages ✅
4. Make the site available at your Pages URL

## Quick Fix Summary
The main issue is **workflow permissions**. GitHub Actions needs "Read and write permissions" to create the Pages site. The other steps are also important but the permissions fix is critical.

## Troubleshooting
If you continue to see permission errors:
1. Verify the repository has GitHub Pages enabled
2. Check that the Pages source is set to "GitHub Actions"
3. Ensure the workflow permissions include `pages: write` and `id-token: write`

The deployment workflow will work once GitHub Pages is properly configured in the repository settings.