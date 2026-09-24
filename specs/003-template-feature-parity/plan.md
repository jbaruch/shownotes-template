# Implementation Plan: Template Feature Parity

**Branch**: `003-template-feature-parity` | **Date**: 2026-09-23 | **Spec**: [spec.md](spec.md)

## Summary

Port the reusable media-embed and AI-guide capabilities from the populated `shownotes` instance into the template. Normalize third-party URLs in a Liquid filter plugin, render them through the existing resource include, keep custom Notist hosts configurable, align the CSP with every supported iframe origin, and generate `llms.txt` from existing talk and skill metadata.

## Technical Context

**Language/Version**: Ruby 3.3.6, Liquid, HTML, Markdown, YAML
**Primary Dependencies**: Jekyll 4.x, Liquid, Minitest, Nokogiri
**Storage**: Repository files and generated static-site output
**Testing**: Minitest unit and integration tests plus Jekyll production build
**Target Platform**: GitHub Pages and local Jekyll server
**Project Type**: Static web site template
**Performance Goals**: No additional network request during build; one-pass iteration over talks
**Constraints**: GitHub Pages-compatible plugins, baseurl-safe links, strict host validation, no personal defaults
**Scale/Scope**: Hundreds of talk documents and a small configurable host list

## Constitution Check

- **Quality-First — PASS**: Tests cover the real Liquid include, CSP, generated guide, and build output.
- **Simplicity — PASS**: One small filter module centralizes URL parsing; no new runtime dependency is required.
- **User-Focused — PASS**: Embeds retain timestamps and degrade to links; guide generation is automatic.
- **Template Integrity — PASS**: Personal content is excluded and custom Notist domains are configuration-driven.
- **Authentic Design — PASS**: Existing components and preview styling are reused without visual redesign.

The check remains valid after design: all generated content uses existing entities and layouts, and no exception requires complexity tracking.

## Project Structure

```text
_plugins/resource_embed_filters.rb         # URL validation and normalization
_includes/embedded_resource.html           # Player/preview rendering
_layouts/default.html                      # Guide discovery and frame policy
_config.yml                                # Optional trusted Notist domains
llms.txt                                   # Generated agent guide source
docs/USAGE.md                              # User configuration and behavior
test/impl/unit/embedded_resource_include_test.rb
test/impl/integration/llms_txt_test.rb
.github/workflows/{ci,deploy}.yml           # Path triggers
specs/003-template-feature-parity/          # Feature artifacts
```

**Structure Decision**: Extend the existing Jekyll plugin/include/layout boundaries. Tests live in the repository's established unit and integration suites.

## Complexity Tracking

No constitution violations.
