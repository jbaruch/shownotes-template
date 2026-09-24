# Quickstart: Template Feature Parity

1. Run `bundle exec ruby test/impl/unit/embedded_resource_include_test.rb`.
2. Run `bundle exec ruby test/impl/integration/llms_txt_test.rb`.
3. Run `bundle exec ruby test/run_tests.rb`.
4. Run `JEKYLL_ENV=production bundle exec jekyll build --config _config.yml,_config_test.yml`.
5. Inspect `_test_site/llms.txt` and one rendered talk page.

To allow a custom Notist domain, add its hostname under `resource_embeds.notist_custom_domains` in `_config.yml`. Do not include a scheme or path.
