# Template Sync Analysis - Spec Complete

## Summary

This spec analyzes the divergence between the shownotes main repository and the shownotes-template repository, identifying which changes should be synchronized to benefit all template users while preserving instance-specific customizations.

## Key Findings

### Commits to Sync to Template ✅

1. **1f977c6** - "Fix production website issues: add plugin debugging, error handling, and exclude sample talk"
   - Plugin improvements with debugging output
   - Error handling with fallback values
   - Priority change to :highest
   - Sample talk moved to docs/templates/
   - .gitignore update
   - Enhanced plugin tests
   - New production health tests

2. **bb100cf** - "Complete website-health-check spec: Update documentation"
   - Plugin troubleshooting guide
   - Sample talk template reference
   - Production health test documentation
   - Sample talk template file

### Commits to Keep Instance-Specific ❌

1. **cc5710f** - "Fix: Correct URL and baseurl for custom domain"
   - Custom domain configuration (speaking.jbaru.ch)
   - Empty baseurl for root domain
   - Specific to jbaruch instance

## Critical Finding: Template Contains Personal Content

**Issue:** The template repository currently contains 50+ personal conference talks and thumbnails that should NOT be in a template.

**Impact:** New users who fork the template get confused by all the personal content and don't understand what to remove vs. what to keep.

**Solution:** Clean up the template to contain:
- ✅ Empty _talks/ directory (or with .gitkeep)
- ✅ Only placeholder-thumbnail.svg in assets/images/thumbnails/
- ✅ sample-talk.md only in docs/templates/ as a reference

## Implementation Approach

The implementation will:
1. Create feature branch in template repository
2. **Clean up personal content (remove all talks and thumbnails)**
3. Cherry-pick the two template-worthy commits
4. Validate configuration preserves placeholder values
5. Run full test suite
6. Review all changes for instance-specific content
7. Push to template with detailed documentation

## Next Steps

To execute this spec:
1. Open `.kiro/specs/template-sync-analysis/tasks.md`
2. Click "Start task" next to task 1
3. Follow the implementation plan step by step

All tasks are marked as required to ensure comprehensive validation and documentation.

## Files Created

- `requirements.md` - User stories and acceptance criteria
- `design.md` - Detailed analysis and recommendations
- `tasks.md` - Step-by-step implementation plan
- `SPEC-COMPLETE.md` - This summary document

## Approval Status

- ✅ Requirements approved
- ✅ Design approved
- ✅ Tasks approved (all required)
- ✅ Ready for implementation
