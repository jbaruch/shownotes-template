# frozen_string_literal: true

require 'minitest/autorun'
require 'jekyll'
require 'yaml'

# Unit tests for Template Format Consistency (TS-200 through TS-210)
# Maps to Gherkin: "Template format in documentation matches actual implementation"
class TemplateFormatConsistencyTest < Minitest::Test
  def setup
    @readme_path = File.join(Dir.pwd, 'README.md')
    @talk_example_path = File.join(Dir.pwd, '_talks', '2025-06-20-voxxed-luxembourg-technical-enshittification.md')
  end

  # TS-200: README template format matches actual talk file format
  def test_readme_template_matches_actual_format
    skip 'README.md not found' unless File.exist?(@readme_path)
    skip 'Example talk file not found' unless File.exist?(@talk_example_path)

    readme_content = File.read(@readme_path)
    talk_content = File.read(@talk_example_path)

    # Extract template examples from README
    readme_template = extract_template_from_readme(readme_content)
    skip 'No template example found in README' if readme_template.nil?

    # Check that README template structure matches actual talk file
    assert_template_format_consistency(readme_template, talk_content)
  end

  # TS-201: README shows correct metadata fields that are actually extracted
  def test_readme_metadata_fields_match_extractor
    skip 'README.md not found' unless File.exist?(@readme_path)

    readme_content = File.read(@readme_path)
    readme_fields = extract_metadata_fields_from_readme(readme_content)

    # These are the fields our markdown parser actually extracts
    expected_fields = ['conference', 'date', 'slides', 'video']

    expected_fields.each do |field|
      assert_includes readme_fields, field,
                      "README should document '#{field}' field that the parser extracts"
    end
  end

  # TS-202: README shows correct markdown metadata format (not YAML frontmatter)
  def test_readme_shows_markdown_metadata_format
    skip 'README.md not found' unless File.exist?(@readme_path)

    readme_content = File.read(@readme_path)

    # Should show markdown metadata format like **Conference:** not YAML
    assert_includes readme_content, '**Conference:**',
                    'README should show markdown metadata format with **Conference:**'

    assert_includes readme_content, '**Date:**',
                    'README should show markdown metadata format with **Date:**'

    # Should NOT show YAML frontmatter format
    refute_includes readme_content, 'conference:',
                    'README should not show YAML frontmatter format for conference'

    refute_includes readme_content, 'date:',
                    'README should not show YAML frontmatter format for date'
  end

  private

  def extract_template_from_readme(content)
    # Look for the talk template code block specifically
    # Find all yaml blocks and return the one containing the talk template
    blocks = content.scan(/```yaml(.*?)```/m)
    talk_template_block = blocks.find { |block| block[0].include?('**Conference:**') }
    return talk_template_block[0].strip if talk_template_block
    
    # Fallback to original logic if no talk template found
    if content =~ /```yaml(.*?)```/m
      return $1.strip
    elsif content =~ /```(.*?)```/m
      return $1.strip
    end
    nil
  end

  def extract_metadata_fields_from_readme(content)
    fields = []
    # Look for **Field:** patterns
    content.scan(/\*\*(\w+):\*\*/).each { |match| fields << match[0].downcase }
    fields.uniq
  end

  def assert_template_format_consistency(readme_template, talk_content)
    # Check that README shows the correct markdown metadata format
    readme_has_markdown_meta = readme_template.include?('**Conference:**')
    talk_has_markdown_meta = talk_content.include?('**Conference:**')

    assert readme_has_markdown_meta, 'README template should show markdown metadata format with **Conference:**'
    assert talk_has_markdown_meta, 'Talk file should use markdown metadata format with **Conference:**'

    # Check that neither uses YAML frontmatter for these fields
    readme_has_yaml_meta = readme_template.match?(/^conference:/)
    talk_has_yaml_meta = talk_content.match?(/^conference:/)

    refute readme_has_yaml_meta, 'README should not show YAML frontmatter format for conference'
    refute talk_has_yaml_meta, 'Talk file should not use YAML frontmatter format for conference'
  end
end
