# frozen_string_literal: true

require 'minitest/autorun'
require 'jekyll'
require 'tmpdir'
require 'fileutils'
require_relative '../../../_plugins/skill_processor'

# Unit tests for the skill processor plugin (feature 002-talk-skill-section).
# Covers data-model.md validation rules 1-5, body rendering, sanitizing,
# heading demotion, and the shape of the data attached to a talk document.
class SkillProcessorTest < Minitest::Test
  REL = '_skills/demo-talk/SKILL.md'
  PREFIX = "Skill #{REL}: "

  def setup
    @processor = Jekyll::SkillProcessor.new
    @tmp_dirs = []
  end

  def teardown
    @tmp_dirs.each { |dir| FileUtils.rm_rf(dir) }
  end

  # --- parsing and validation (rules 1-5) ---------------------------------

  def test_parse_valid_skill_returns_name_description_and_body
    skill = @processor.send(:parse_skill, valid_raw, REL)

    assert_equal 'demo-skill', skill['name']
    assert_equal 'Does demo things.', skill['description']
    assert_includes skill['body'], '# Heading'
    refute_includes skill['body'], 'name: demo-skill', 'body must not contain the front matter'
  end

  def test_parse_trims_surrounding_whitespace_from_description
    raw = "---\nname: demo-skill\ndescription: '  padded  '\n---\nbody\n"
    skill = @processor.send(:parse_skill, raw, REL)

    assert_equal 'padded', skill['description']
  end

  def test_parse_accepts_unicode_in_description_and_body
    raw = "---\nname: demo-skill\ndescription: Uses ✓ marks — and dashes\n---\n\nBody with ünïcödé ✓\n"
    skill = @processor.send(:parse_skill, raw, REL)

    assert_equal 'Uses ✓ marks — and dashes', skill['description']
    assert_includes skill['body'], 'ünïcödé ✓'
  end

  def test_parse_fails_without_front_matter
    assert_skill_error("# Just markdown\n", 'missing front matter (file must start with ---)')
  end

  def test_parse_fails_on_unparseable_yaml
    assert_skill_error("---\nname: [unclosed\ndescription: x\n---\n", 'front matter is not valid YAML')
  end

  def test_parse_fails_when_front_matter_is_not_a_mapping
    assert_skill_error("---\n- just\n- a list\n---\n", 'front matter is not valid YAML: expected a mapping')
  end

  def test_parse_fails_on_missing_name
    assert_skill_error("---\ndescription: present\n---\nbody\n", "missing required field 'name'")
  end

  def test_parse_fails_on_empty_name
    assert_skill_error("---\nname: ''\ndescription: present\n---\nbody\n", "missing required field 'name'")
  end

  def test_parse_fails_on_missing_description
    assert_skill_error("---\nname: demo-skill\n---\nbody\n", "missing required field 'description'")
  end

  def test_parse_fails_on_whitespace_only_description
    assert_skill_error("---\nname: demo-skill\ndescription: '   '\n---\nbody\n", "missing required field 'description'")
  end

  def test_parse_fails_on_non_string_description
    assert_skill_error("---\nname: demo-skill\ndescription: 42\n---\nbody\n", "missing required field 'description'")
  end

  def test_parse_fails_on_name_with_uppercase_spaces_or_markup
    ['Demo Skill', 'demo_skill', 'demo--skill', '-demo', 'demo-', '<b>x</b>', 'demo/skill'].each do |bad|
      assert_skill_error("---\nname: \"#{bad}\"\ndescription: present\n---\n",
                         "'name' must be lowercase letters, digits and hyphens (used as the install directory)")
    end
  end

  def test_parse_fails_on_name_longer_than_64_characters
    long_name = "#{'a' * 63}-b" # 65 chars, otherwise valid
    assert_skill_error("---\nname: #{long_name}\ndescription: present\n---\n",
                       "'name' must be lowercase letters, digits and hyphens (used as the install directory)")
  end

  def test_parse_accepts_name_of_exactly_64_characters
    name = "#{'a' * 62}-b" # 64 chars
    skill = @processor.send(:parse_skill, "---\nname: #{name}\ndescription: present\n---\n", REL)

    assert_equal name, skill['name']
  end

  def test_parse_fails_on_description_longer_than_1024_characters
    assert_skill_error("---\nname: demo-skill\ndescription: #{'x' * 1025}\n---\n",
                       "'description' must be at most 1024 characters")
  end

  def test_parse_accepts_description_of_exactly_1024_characters
    skill = @processor.send(:parse_skill, "---\nname: demo-skill\ndescription: #{'x' * 1024}\n---\n", REL)

    assert_equal 1024, skill['description'].length
  end

  def test_validation_failures_are_jekyll_fatal_exceptions
    error = assert_raises(Jekyll::Errors::FatalException) do
      @processor.send(:parse_skill, "no front matter", REL)
    end
    assert error.message.start_with?(PREFIX), "message must start with the source path, got: #{error.message}"
  end

  # --- rendering ----------------------------------------------------------

  def test_render_body_returns_empty_string_for_blank_body
    assert_equal '', @processor.send(:render_body, site, '')
    assert_equal '', @processor.send(:render_body, site, "\n\n  \n")
    assert_equal '', @processor.send(:render_body, site, nil)
  end

  def test_render_body_renders_markdown_to_html
    html = @processor.send(:render_body, site, "Use **this** and `that`.\n")

    assert_includes html, '<strong>this</strong>'
    assert_match(%r{<code[^>]*>that</code>}, html)
  end

  def test_render_body_neutralises_script_tags
    html = @processor.send(:render_body, site, "Text\n\n<script>alert(1)</script>\n\nMore\n")

    refute_match(/<script/i, html, 'no executable script may survive rendering')
    assert_includes html, '[removed]'
    assert_includes html, '<p>More</p>'
  end

  def test_render_body_demotes_headings_by_two_levels_and_clamps_at_h6
    body = "# One\n\n## Two\n\n### Three\n\n#### Four\n\n##### Five\n\n###### Six\n"
    html = @processor.send(:render_body, site, body)

    refute_match(/<h[12]\b/, html, 'h1/h2 must not appear inside the section body')
    assert_match(/<h3[^>]*>One<\/h3>/, html)
    assert_match(/<h4[^>]*>Two<\/h4>/, html)
    assert_match(/<h5[^>]*>Three<\/h5>/, html)
    assert_match(/<h6[^>]*>Four<\/h6>/, html)
    assert_match(/<h6[^>]*>Five<\/h6>/, html)
    assert_match(/<h6[^>]*>Six<\/h6>/, html)
    refute_match(/<h[789]/, html)
  end

  def test_render_body_keeps_unicode_intact
    html = @processor.send(:render_body, site, "Ünïcödé ✓ — works\n")

    assert_includes html, 'Ünïcödé ✓ — works'
  end

  # --- attached data ------------------------------------------------------

  def test_build_skill_data_has_the_documented_shape
    skill = @processor.send(:parse_skill, valid_raw, REL)
    data = @processor.send(:build_skill_data, site, skill, 'demo-talk', REL)

    assert_equal %w[description html install_dir name source_path url], data.keys.sort
    assert_equal 'demo-skill', data['name']
    assert_equal 'Does demo things.', data['description']
    assert_equal '/skills/demo-talk/SKILL.md', data['url']
    assert_equal REL, data['source_path']
    assert_equal '~/.claude/skills/demo-skill', data['install_dir']
    assert_includes data['html'], '<h3'
  end

  private

  def valid_raw(body: "# Heading\n\nUse **this**.\n")
    "---\nname: demo-skill\ndescription: Does demo things.\n---\n\n#{body}"
  end

  def assert_skill_error(raw, expected_fragment)
    error = assert_raises(Jekyll::Errors::FatalException) { @processor.send(:parse_skill, raw, REL) }
    assert error.message.start_with?(PREFIX), "expected prefix #{PREFIX.inspect}, got: #{error.message}"
    assert_includes error.message, expected_fragment
  end

  def site
    @site ||= begin
      dir = Dir.mktmpdir('skill_processor_test')
      @tmp_dirs << dir
      Jekyll::Site.new(Jekyll.configuration('source' => dir,
                                            'destination' => File.join(dir, '_site'),
                                            'quiet' => true))
    end
  end
end
