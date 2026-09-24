# Tasks: Template Feature Parity

**Input**: Design documents from `/specs/003-template-feature-parity/`

## Phase 1: Tests and configuration contract

- [x] T001 [P] [US1] Add YouTube and Vimeo rendering, fallback, preview, and CSP tests in `test/impl/unit/embedded_resource_include_test.rb`
- [x] T002 [P] [US2] Add canonical/configured Notist rendering and CSP tests in `test/impl/unit/embedded_resource_include_test.rb`
- [x] T003 [P] [US3] Add root/subpath guide generation and discovery tests in `test/impl/integration/llms_txt_test.rb`

## Phase 2: Recording embeds

- [x] T004 [US1] Implement validated YouTube and Vimeo normalization in `_plugins/resource_embed_filters.rb`
- [x] T005 [US1] Render normalized recording embeds and previews in `_includes/embedded_resource.html`
- [x] T006 [US1] Allow the Vimeo player origin in `_layouts/default.html`

## Phase 3: Notist slide embeds

- [x] T007 [US2] Implement canonical and configured custom-domain Notist normalization in `_plugins/resource_embed_filters.rb`
- [x] T008 [US2] Render Notist embeds and previews in `_includes/embedded_resource.html`
- [x] T009 [US2] Add portable Notist configuration in `_config.yml` and matching frame policy in `_layouts/default.html`

## Phase 4: Agent guide

- [x] T010 [US3] Add generated talk and skill navigation in `llms.txt`
- [x] T011 [US3] Add guide discovery metadata in `_layouts/default.html`
- [x] T012 [US3] Add guide path triggers in `.github/workflows/ci.yml` and `.github/workflows/deploy.yml`

## Phase 5: Documentation and validation

- [x] T013 [P] Document supported URLs, custom domains, and the agent guide in `docs/USAGE.md`
- [x] T014 Run focused tests, the complete non-external suite, and the production Jekyll build
- [x] T015 Verify the implementation against `specs/003-template-feature-parity/quickstart.md`
- [x] T016 [P] Port the missing shared test setup in `test/test_helper.rb`, unignore it in `.gitignore`, and remove the personal Notist hostname from `lib/utils/url_validator.rb`

## Dependencies & Execution Order

- T001–T003 define the expected behavior before implementation.
- T004–T006 complete US1; T007–T009 complete US2; T010–T012 complete US3.
- T013 can proceed after behavior stabilizes. T014–T015 require all implementation tasks.

## Independent Test Criteria

- **US1**: Supported recordings render normalized players; invalid hosts fall back; frame policy allows the players.
- **US2**: Canonical and configured Notist hosts embed; unconfigured hosts fall back; policy matches configuration.
- **US3**: Root and subpath builds generate complete, ordered guides and advertise them from shared pages.

## MVP

US1 (T001, T004–T006) is the minimum independently valuable slice.
