# Deployment Guide

## Push to GitHub and Enable Automation

### 1. Push to GitHub Repository

```bash
# Add your GitHub repository as remote origin
git remote add origin https://github.com/YOUR_USERNAME/shownotes.git

# Push main branch and all tags
git push -u origin main
git push origin --tags
```

### 2. Enable GitHub Pages

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Pages**
3. Set **Source** to "GitHub Actions"
4. The deploy workflow will automatically trigger on pushes to main

### 3. GitHub Actions Setup

The repository includes three automated workflows:

#### CI Workflow (`/.github/workflows/ci.yml`)
- **Triggers**: Push to main/develop, Pull Requests
- **Features**: 
  - Multi-version Ruby testing (2.6, 2.7, 3.0)
  - Complete test suite execution (139 tests, 792 assertions)
  - Security scanning with bundler-audit
  - Jekyll build verification
- **Artifacts**: Build outputs uploaded for review

#### Deploy Workflow (`/.github/workflows/deploy.yml`)  
- **Triggers**: Push to main branch
- **Features**:
  - Test-first deployment (fails if tests fail)
  - Production Jekyll builds
  - Automatic GitHub Pages deployment
- **Requirements**: Tests must pass (100% success rate required)

#### Dependencies Workflow (`/.github/workflows/dependencies.yml`)
- **Triggers**: Weekly schedule (Mondays 6 AM UTC) + manual
- **Features**:
  - Automated dependency updates
  - Security audit database refresh
  - Automated PR creation for successful updates
  - Test compatibility verification

### 4. Repository Settings

#### Enable Actions
1. Go to **Settings** → **Actions** → **General**
2. Set "Actions permissions" to "Allow all actions and reusable workflows"
3. Set "Workflow permissions" to "Read and write permissions"

#### Pages Configuration
1. **Settings** → **Pages**
2. **Source**: "Deploy from a branch" → "GitHub Actions"
3. The site will be available at: `https://YOUR_USERNAME.github.io/shownotes/`

### 5. Verify Deployment

After pushing:

1. **Check Actions**: Go to **Actions** tab to monitor workflow execution
2. **Verify Tests**: Ensure all 139 tests pass (792 assertions, 0 failures)
3. **Check Build**: Confirm Jekyll build succeeds
4. **Test Site**: Visit the deployed URL to verify functionality

### 6. Development Workflow

```bash
# Create feature branch
git checkout -b feature/new-functionality

# Make changes and run tests locally
bundle exec rake test

# Commit and push (triggers CI)
git commit -m "Add new functionality"
git push origin feature/new-functionality

# Create PR → CI runs automatically
# Merge PR → Deployment workflow triggers
```

### 7. Quality Gates

The automation enforces strict quality standards:

✅ **All tests must pass** (139 runs, 792 assertions, 0 failures)  
✅ **Security audit must be clean** (bundler-audit)  
✅ **Jekyll build must succeed** (static site generation)  
✅ **Performance tests must pass** (load time requirements)  
✅ **E2E workflows must work** (user experience validation)

### 8. Monitoring

- **GitHub Actions**: Monitor workflow status and logs
- **Pages**: Check deployment status and build logs  
- **Security**: Review automated dependency PRs weekly
- **Performance**: CI validates page load times and responsiveness

### 9. Troubleshooting

#### Common Issues

**Tests fail in GitHub Actions but pass locally:**
- Check Ruby version compatibility (CI tests 2.6, 2.7, 3.0)
- Verify BUNDLE_FORCE_RUBY_PLATFORM environment variable
- Review architecture-specific dependencies (Nokogiri)

**Deployment fails:**
- Ensure tests pass first (deployment blocked if tests fail)
- Check GitHub Pages settings and permissions
- Verify Jekyll configuration and build process

**Security audit failures:**
- Review automated dependency update PRs
- Update vulnerable dependencies manually if needed
- Check bundler-audit output for specific issues

### 10. Success Metrics

When everything is working correctly:

- **CI Status**: ✅ All workflows passing
- **Test Results**: 139 runs, 792 assertions, 0 failures, 0 errors
- **Security**: No known vulnerabilities in dependencies
- **Performance**: Page loads under performance thresholds
- **Accessibility**: WCAG compliance maintained
- **Site Availability**: GitHub Pages deployment successful

The platform is now ready for production use with:
- Mobile-optimized conference talk pages
- QR code accessibility
- Comprehensive resource management
- Security compliance
- Performance optimization
- Automated CI/CD pipeline