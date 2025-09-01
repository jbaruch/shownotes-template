# frozen_string_literal: true

require 'minitest/autorun'

# Unit tests for Template Format Consistency (TS-200 through TS-205)
# Maps to Gherkin: "Template format in documentation matches actual implementation"
class TemplateFormatConsistencyTest < Minitest::Test
  def setup
    @readme_path = File.join(Dir.pwd, 'README.md')
    @talk_example_path = File.join(Dir.pwd, '_talks', '2025-06-20-voxxed-days-luxembourg-2025-technical-enshittification-why-everything-in-it-is-.md')
  end

  # TS-200: README shows correct metadata format (markdown, not YAML)
  def test_readme_shows_correct_metadata_format
    skip 'README.md not found' unless File.exist?(@readme_path)

    readme_content = File.read(@readme_path)

    # README should show the correct markdown metadata format
    assert_includes readme_content, '**Conference:**',
                    'README should show markdown metadata format with **Conference:**'

    assert_includes readme_content, '**Date:**',
                    'README should show markdown metadata format with **Date:**'

    # README should NOT show the broken YAML format that would confuse users
    refute_match(/^\s*conference:\s*/, readme_content,
                'README should not show YAML frontmatter format for conference')

    refute_match(/^\s*date:\s*/, readme_content,
                'README should not show YAML frontmatter format for date')
  end

  # TS-201: Actual talk files use the correct markdown metadata format
  def test_talk_files_use_correct_format
    skip 'Example talk file not found' unless File.exist?(@talk_example_path)

    talk_content = File.read(@talk_example_path)

    # Talk files should use markdown metadata format
    assert_includes talk_content, '**Conference:**',
                    'Talk files should use markdown metadata format with **Conference:**'

    assert_includes talk_content, '**Date:**',
                    'Talk files should use markdown metadata format with **Date:**'

    # Talk files should NOT use YAML frontmatter for metadata
    refute_includes talk_content, 'conference:',
                    'Talk files should not use YAML frontmatter format for conference'

    refute_includes talk_content, 'date:',
                    'Talk files should not use YAML frontmatter format for date'
  end

  # TS-202: README and talk files are consistent in format
  def test_readme_and_talk_files_consistent
    skip 'README.md not found' unless File.exist?(@readme_path)
    skip 'Example talk file not found' unless File.exist?(@talk_example_path)

    readme_content = File.read(@readme_path)
    talk_content = File.read(@talk_example_path)

    # Both should use markdown metadata format
    readme_uses_markdown = readme_content.include?('**Conference:**')
    talk_uses_markdown = talk_content.include?('**Conference:**')

    assert readme_uses_markdown, 'README should use markdown metadata format'
    assert talk_uses_markdown, 'Talk files should use markdown metadata format'

    # Neither should use YAML frontmatter format
    readme_uses_yaml = readme_content.include?('conference:')
    talk_uses_yaml = talk_content.include?('conference:')

    refute readme_uses_yaml, 'README should not use YAML frontmatter format'
    refute talk_uses_yaml, 'Talk files should not use YAML frontmatter format'
  end

  # TS-203: README includes all required metadata fields
  def test_readme_includes_required_fields
    skip 'README.md not found' unless File.exist?(@readme_path)

    readme_content = File.read(@readme_path)

    # README should document the fields that the parser actually extracts
    required_fields = ['**Conference:**', '**Date:**', '**Slides:**', '**Video:**']

    required_fields.each do |field|
      assert_includes readme_content, field,
                      "README should document required field: #{field}"
    end
  end

  # TS-204: README template example is realistic and complete
  def test_readme_template_is_complete
    skip 'README.md not found' unless File.exist?(@readme_path)

    readme_content = File.read(@readme_path)

    # README should show a complete template with all key elements
    assert_includes readme_content, 'layout: talk',
                    'README template should include layout specification'

    assert_includes readme_content, '# Talk Title Here',
                    'README template should include title format'

    assert_includes readme_content, '## Resources',
                    'README template should include resources section'
  end

  # TS-205: Regression test - ensures format consistency is maintained
  def test_format_consistency_regression
    # This test would fail if someone changed the format back to YAML
    skip 'Example talk file not found' unless File.exist?(@talk_example_path)

    talk_content = File.read(@talk_example_path)

    # Ensure the talk file still uses the correct format
    assert_includes talk_content, '**Conference:** Voxxed Days Luxembourg 2025',
                    'Talk should contain correct conference metadata'

    assert_includes talk_content, '**Date:** 2025-06-20',
                    'Talk should contain correct date metadata'
  end
end
