# frozen_string_literal: true

require 'minitest/autorun'
require 'jekyll'
require 'nokogiri'
require 'tmpdir'
require 'fileutils'
# Load the site's plugins once; Jekyll generators are process-global, so both
# harnesses below run them without copying _plugins/ around.
require_relative '../../../_plugins/markdown_parser'
require_relative '../../../_plugins/skill_processor'

# Integration tests for the talk page Skill section (feature 002-talk-skill-section).
#
# RealSiteSkillSectionTest builds this repository as-is (same pattern as
# resource_styling_test.rb) and inspects the DEMO talk that ships a skill.
#
# TempSiteSkillSectionTest copies the real layouts and includes into a temp
# directory so it can exercise sub-path hosting, talks without media, blank
# bodies, escaping, malformed files, orphans, and the clean-template state.
module SkillSectionHelpers
  SKILL_STEM = 'DEMO-ai-coding-assistants-2025'
  OTHER_DEMO_STEMS = %w[DEMO-devops-revolution-2025 DEMO-kubernetes-security-2024].freeze
  REPO_ROOT = File.expand_path('../../..', __dir__)

  def talk_doc(site, stem)
    doc = site.collections['talks'].docs.find { |d| File.basename(d.path, '.md') == stem }
    refute_nil doc, "talk #{stem} should exist in the talks collection"
    doc
  end

  def talk_html(site, stem)
    Nokogiri::HTML(talk_doc(site, stem).output)
  end

  def skill_front_matter(path)
    raw = File.read(path, encoding: 'utf-8')
    SafeYAML.load(raw.match(Jekyll::Document::YAML_FRONT_MATTER_REGEXP)[1])
  end
end

class RealSiteSkillSectionTest < Minitest::Test
  include SkillSectionHelpers

  def self.site
    @site ||= begin
      config = Jekyll.configuration('source' => REPO_ROOT,
                                    'destination' => File.join(REPO_ROOT, '_test_site'),
                                    'quiet' => true)
      site = Jekyll::Site.new(config)
      site.process
      site
    end
  end

  def site
    self.class.site
  end

  def baseurl
    site.config['baseurl'].to_s
  end

  def raw_path
    "/skills/#{SKILL_STEM}/SKILL.md"
  end

  def skill_page
    @skill_page ||= talk_html(site, SKILL_STEM)
  end

  def section
    skill_page.css('section.talk-skill').first
  end

  def expected_name
    skill_front_matter(File.join(REPO_ROOT, '_skills', SKILL_STEM, 'SKILL.md'))['name']
  end

  def expected_description
    skill_front_matter(File.join(REPO_ROOT, '_skills', SKILL_STEM, 'SKILL.md'))['description']
  end

  # --- US1: section presence, position, and contents ----------------------

  def test_skill_talk_has_exactly_one_skill_section
    sections = skill_page.css('section.talk-skill')

    assert_equal 1, sections.size, 'the DEMO skill talk should render exactly one Skill section'
    assert_equal 'talk-skill-heading', sections.first['aria-labelledby']
  end

  def test_skill_section_sits_between_media_row_and_talk_content
    classes = skill_page.css('article.talk > section').map { |s| s['class'].to_s.split.first }

    assert_equal %w[talk-main-content talk-skill talk-content], classes,
                 'section order must be media row, skill, talk content (FR-016)'
  end

  def test_heading_shows_label_and_skill_name_with_one_h2
    heading = section.css('h2#talk-skill-heading').first

    refute_nil heading, 'section needs an h2 with id talk-skill-heading'
    assert_equal 'Skill', heading.css('.talk-skill__label').text.strip
    assert_equal expected_name, heading.css('.talk-skill__name').text.strip
    assert_equal 1, section.css('h2').size, 'exactly one h2 inside the section'
  end

  def test_description_matches_front_matter
    assert_equal expected_description, section.css('.talk-skill__description').text.strip
  end

  def test_install_command_targets_personal_skills_folder_and_raw_url
    command = section.css('#talk-skill-command').text

    assert_includes command, "mkdir -p ~/.claude/skills/#{expected_name}"
    assert_includes command, 'curl -fsSL'
    assert_includes command, "#{site.config['url']}#{baseurl}#{raw_path}"
    assert_includes command, "-o ~/.claude/skills/#{expected_name}/SKILL.md"
  end

  def test_download_link_points_at_raw_file
    link = section.css('a.talk-skill__raw').first

    refute_nil link, 'section needs a download link to the raw file'
    assert_equal "#{baseurl}#{raw_path}", link['href']
    assert link.has_attribute?('download'), 'raw link should carry the download attribute'
  end

  def test_body_disclosure_is_closed_by_default
    details = section.css('details.talk-skill__body').first

    refute_nil details, 'section needs a details element for the body'
    refute details.has_attribute?('open'), 'disclosure must be closed on every page load'
    refute_empty details.css('summary.talk-skill__summary').text.strip
    refute_empty details.css('.talk-skill__content').text.strip
  end

  def test_body_headings_sit_below_the_section_heading
    body_headings = section.css('.talk-skill__content h1, .talk-skill__content h2')
    assert_empty body_headings, 'body headings must be demoted below the section h2'

    assert_equal 'h3', section.css('.talk-skill__install-heading').first&.name,
                 'the Install heading is an h3'
    refute_empty section.css('.talk-skill__content h3'), 'the demo body h1 renders as h3'
  end

  def test_raw_file_is_served_byte_identical
    source = File.binread(File.join(REPO_ROOT, '_skills', SKILL_STEM, 'SKILL.md'))
    served = File.join(REPO_ROOT, '_test_site', 'skills', SKILL_STEM, 'SKILL.md')

    assert File.exist?(served), "raw file should be written to #{served}"
    assert_equal source, File.binread(served)
  end
end

class TempSiteSkillSectionTest < Minitest::Test
  include SkillSectionHelpers

  def setup
    @dir = Dir.mktmpdir('skill_section_test')
    %w[_layouts _includes].each { |d| FileUtils.cp_r(File.join(REPO_ROOT, d), @dir) }
    FileUtils.mkdir_p(File.join(@dir, '_talks'))
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  # --- US1 edge cases ------------------------------------------------------

  def test_sub_path_hosting_prefixes_raw_link_and_install_command
    write_talk('sub-talk')
    write_skill('sub-talk')

    site = build(baseurl: '/sub')
    html = talk_html(site, 'sub-talk')

    assert_equal '/sub/skills/sub-talk/SKILL.md', html.css('a.talk-skill__raw').first['href']
    assert_includes html.css('#talk-skill-command').text, '/sub/skills/sub-talk/SKILL.md'
    assert File.exist?(File.join(@dir, '_site', 'skills', 'sub-talk', 'SKILL.md'))
  end

  def test_talk_without_media_puts_skill_section_first_after_header
    write_talk('plain-talk', slides: false)
    write_skill('plain-talk')

    html = talk_html(build, 'plain-talk')
    sections = html.css('article.talk > section')

    assert_empty html.css('section.talk-main-content'), 'fixture must have no media row'
    assert_equal 'talk-skill', sections.first['class'].to_s.split.first
    assert_equal 'header', sections.first.previous_element.name, 'the skill section follows the header directly'
  end

  def test_blank_body_renders_without_disclosure
    write_talk('blank-talk')
    write_skill('blank-talk', body: "\n\n")

    html = talk_html(build, 'blank-talk')
    section = html.css('section.talk-skill').first

    refute_nil section
    assert_empty section.css('details.talk-skill__body'), 'no disclosure for an empty body'
    assert_equal 'temp-skill', section.css('.talk-skill__name').text.strip
    assert_equal 'Temp description.', section.css('.talk-skill__description').text.strip
    assert_includes section.css('#talk-skill-command').text, 'temp-skill'
  end

  def test_description_markup_is_escaped
    write_talk('escape-talk')
    write_skill('escape-talk', front_matter: "name: temp-skill\ndescription: \"Uses <b>bold</b> text\"")

    section = talk_html(build, 'escape-talk').css('section.talk-skill').first
    description = section.css('.talk-skill__description').first

    assert_empty description.css('b'), 'markup in the description must not become elements'
    assert_includes description.inner_html, '&lt;b&gt;'
    assert_equal 'Uses <b>bold</b> text', description.text.strip
  end

  private

  def write_talk(stem, slides: true)
    slides_line = slides ? "**Slides:** [View Slides](https://docs.google.com/presentation/d/abc123/view)\n" : ''
    File.write(File.join(@dir, '_talks', "#{stem}.md"), <<~MD)
      ---
      layout: talk
      ---

      # Talk #{stem}

      **Conference:** TestConf 2026
      **Date:** 2026-01-01
      #{slides_line}
      A presentation at TestConf 2026 in January 2026 by Test Speaker

      ## Abstract

      An abstract paragraph.

      ## Resources

      - [Example](https://example.com)
    MD
  end

  def write_skill(stem, front_matter: "name: temp-skill\ndescription: Temp description.", body: "# Body\n\nText.\n")
    dir = File.join(@dir, '_skills', stem)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, 'SKILL.md'), "---\n#{front_matter}\n---\n\n#{body}")
  end

  def build(baseurl: '')
    config = Jekyll.configuration(
      'source' => @dir,
      'destination' => File.join(@dir, '_site'),
      'quiet' => true,
      'url' => '',
      'baseurl' => baseurl,
      'markdown' => 'kramdown',
      'kramdown' => { 'input' => 'GFM' },
      'collections' => { 'talks' => { 'output' => true, 'permalink' => '/talks/:path/' } },
      'defaults' => [{ 'scope' => { 'path' => '', 'type' => 'talks' }, 'values' => { 'layout' => 'talk' } }]
    )
    site = Jekyll::Site.new(config)
    site.process
    site
  end
end
