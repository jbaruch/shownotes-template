# frozen_string_literal: true

require 'minitest/autorun'
require 'jekyll'
require_relative '../../../lib/simple_talk_renderer'

# Unit tests for Talk Information Display (TS-001 through TS-005)
# Maps to Gherkin: "Talk page displays core information correctly"
class TalkInformationDisplayTest < Minitest::Test
  def setup
    @talk_data = {
      'title' => 'Modern JavaScript Patterns',
      'speaker' => 'Jane Developer',
      'conference' => 'JSConf 2024',
      'date' => '2024-03-15',
      'status' => 'completed',
      'description' => 'Exploring modern JavaScript patterns and best practices'
    }
    @renderer = SimpleTalkRenderer.new
  end

  # TS-001: Talk title displays as H1 element
  def test_talk_title_appears_as_h1_heading
    page_html = generate_talk_page(@talk_data)
    
    assert_includes page_html, '<h1 class="talk-title">Modern JavaScript Patterns</h1>',
                    'Talk title should appear as H1 element with talk-title class'
  end

  # TS-002: Speaker name should NOT have a dedicated speaker section/block on individual talk pages
  # (Speaker name in header metadata, footer, and meta tags is acceptable)
  def test_speaker_name_not_on_talk_page
    page_html = generate_talk_page(@talk_data)
    
    # Verify no dedicated speaker section exists in the main talk content
    main_section = extract_section(page_html, 'main-content')
    refute_includes main_section, 'speaker-section',
                    'Dedicated speaker section should not appear in main talk content'
    refute_includes main_section, '<section class="speaker"',
                    'Dedicated speaker section should not appear in main talk content'
    
    # Verify no standalone speaker bio or info block
    refute_includes page_html, '<div class="speaker-bio"',
                    'Speaker bio section should not appear on talk pages'
    refute_includes page_html, '<div class="speaker-info"',
                    'Speaker info section should not appear on talk pages'
    
    # But speaker name in metadata, title, footer, and meta tags is OK
    assert_includes page_html, 'Jane Developer',
                    'Speaker name should still appear somewhere in the document (title, footer, meta)'
  end

  # TS-003: Conference name and date render in metadata section
  def test_conference_and_date_in_metadata
    page_html = generate_talk_page(@talk_data)
    
    assert_includes page_html, '<span class="conference">JSConf 2024</span>',
                    'Conference name should display with conference class'
    
    assert page_html.include?('<time class="date"') && page_html.include?('>March 15, 2024</time>'),
                    'Date should format and display with time element'
    
    # Verify both appear in metadata section
    metadata_section = extract_section(page_html, 'talk-meta')
    assert_includes metadata_section, 'JSConf 2024'
    assert_includes metadata_section, 'March 15, 2024'
  end

  # TS-004: Talk status shows with appropriate visual styling
  def test_status_displays_with_css_class
    page_html = generate_talk_page(@talk_data)
    
    assert_includes page_html, '<span class="status status-completed">Completed</span>',
                    'Status should display with status-specific CSS class'
  end

  # TS-005: Talk description renders from YAML frontmatter
  def test_description_renders_from_frontmatter
    page_html = generate_talk_page(@talk_data)
    
    description_section = extract_section(page_html, 'talk-description')
    assert_includes description_section, 'Exploring modern JavaScript patterns and best practices',
                    'Description should render from frontmatter data'
  end

  private

  # Interface method - now implemented
  def generate_talk_page(talk_data)
    @renderer.generate_talk_page(talk_data)
  end

  # Interface method - now implemented
  def extract_section(html, css_class)
    @renderer.extract_section(html, css_class)
  end
end