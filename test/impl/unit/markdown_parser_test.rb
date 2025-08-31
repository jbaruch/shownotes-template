# frozen_string_literal: true

require 'minitest/autorun'
require 'jekyll'
require_relative '../../../_plugins/markdown_parser'

# Unit tests for Markdown Parser Plugin (TS-221 through TS-235)
# Maps to Gherkin: "Markdown parser plugin correctly extracts metadata from talk content"
class MarkdownParserTest < Minitest::Test
  def setup
    @sample_content = <<~MARKDOWN
      ---
      layout: talk
      ---

      # Technical Enshittification: Why Everything in IT is Horrible Right Now

      **Conference:** Voxxed Days Luxembourg 2025
      **Date:** 2025-06-20
      **Slides:** [View Slides](https://drive.google.com/file/d/1vAOI6cYus5abZHM2zepIQgBBPCN8qLUl/view)
      **Video:** [Watch Video](https://youtube.com/watch?v=iFN1Y_8Cuik)

      Did you notice how everything in IT is crap right now? Services are bloated, slow, and buggy...

      ## Resources

      - [DevOps Tools For Java Developers](https://amzn.to/4io8r3I)
    MARKDOWN

    @parser = Jekyll::MarkdownTalkProcessor.new
  end

  # TS-221: Markdown parser extracts title correctly
  def test_extract_title_from_content
    title = @parser.send(:extract_title_from_content, @sample_content)
    assert_equal 'Technical Enshittification: Why Everything in IT is Horrible Right Now', title
  end

  # TS-222: Markdown parser extracts conference correctly
  def test_extract_conference_from_content
    conference = @parser.send(:extract_metadata_from_content, @sample_content, 'conference')
    assert_equal 'Voxxed Days Luxembourg 2025', conference
  end

  # TS-223: Markdown parser extracts date correctly
  def test_extract_date_from_content
    date = @parser.send(:extract_metadata_from_content, @sample_content, 'date')
    assert_equal '2025-06-20', date
  end

  # TS-224: Markdown parser extracts slides URL correctly
  def test_extract_slides_url_from_content
    slides = @parser.send(:extract_metadata_from_content, @sample_content, 'slides')
    assert_equal 'https://drive.google.com/file/d/1vAOI6cYus5abZHM2zepIQgBBPCN8qLUl/view', slides
  end

  # TS-225: Markdown parser extracts video URL correctly
  def test_extract_video_url_from_content
    video = @parser.send(:extract_metadata_from_content, @sample_content, 'video')
    assert_equal 'https://youtube.com/watch?v=iFN1Y_8Cuik', video
  end

  # TS-226: Markdown parser extracts description correctly
  def test_extract_description_from_content
    description = @parser.send(:extract_description_from_content, @sample_content)
    assert_includes description, 'Did you notice how everything in IT is crap right now?'
  end

  # TS-227: Markdown parser extracts resources correctly
  def test_extract_resources_from_content
    resources = @parser.send(:extract_resources_from_content, @sample_content)
    assert_includes resources, 'DevOps Tools For Java Developers'
    assert_includes resources, 'https://amzn.to/4io8r3I'
  end

  # TS-228: Markdown parser handles missing metadata gracefully
  def test_handles_missing_metadata
    content_without_metadata = <<~MARKDOWN
      ---
      layout: talk
      ---

      # Talk Without Metadata

      This talk has no metadata fields.
    MARKDOWN

    conference = @parser.send(:extract_metadata_from_content, content_without_metadata, 'conference')
    assert_nil conference, 'Missing conference should return nil'

    date = @parser.send(:extract_metadata_from_content, content_without_metadata, 'date')
    assert_nil date, 'Missing date should return nil'
  end

  # TS-229: Markdown parser handles malformed content
  def test_handles_malformed_content
    malformed_content = nil
    title = @parser.send(:extract_title_from_content, malformed_content)
    assert_equal 'Untitled Talk', title, 'Malformed content should return default title'
  end

  # TS-230: Markdown parser extracts URL from markdown links
  def test_extracts_url_from_markdown_links
    content_with_links = <<~MARKDOWN
      **Slides:** [View Slides](https://example.com/slides)
      **Video:** [Watch Video](https://youtube.com/watch?v=abc123)
    MARKDOWN

    slides = @parser.send(:extract_metadata_from_content, content_with_links, 'slides')
    assert_equal 'https://example.com/slides', slides

    video = @parser.send(:extract_metadata_from_content, content_with_links, 'video')
    assert_equal 'https://youtube.com/watch?v=abc123', video
  end

  # TS-231: Markdown parser handles plain URLs without markdown links
  def test_handles_plain_urls
    content_with_plain_urls = <<~MARKDOWN
      **Slides:** https://example.com/slides
      **Video:** https://youtube.com/watch?v=abc123
    MARKDOWN

    slides = @parser.send(:extract_metadata_from_content, content_with_plain_urls, 'slides')
    assert_equal 'https://example.com/slides', slides

    video = @parser.send(:extract_metadata_from_content, content_with_plain_urls, 'video')
    assert_equal 'https://youtube.com/watch?v=abc123', video
  end

  # TS-232: Markdown parser is case-insensitive for field names
  def test_case_insensitive_field_extraction
    content_mixed_case = <<~MARKDOWN
      **conference:** Test Conference 2025
      **DATE:** 2025-01-01
      **Slides:** https://example.com/slides
    MARKDOWN

    conference = @parser.send(:extract_metadata_from_content, content_mixed_case, 'conference')
    assert_equal 'Test Conference 2025', conference

    date = @parser.send(:extract_metadata_from_content, content_mixed_case, 'date')
    assert_equal '2025-01-01', date
  end

  # TS-233: Markdown parser handles multiple metadata fields correctly
  def test_multiple_metadata_fields
    content_multiple = <<~MARKDOWN
      **Conference:** Conference A
      **Date:** 2025-01-01
      **Conference:** Conference B
      **Date:** 2025-01-02
    MARKDOWN

    # Should extract the first occurrence
    conference = @parser.send(:extract_metadata_from_content, content_multiple, 'conference')
    assert_equal 'Conference A', conference

    date = @parser.send(:extract_metadata_from_content, content_multiple, 'date')
    assert_equal '2025-01-01', date
  end

  # TS-234: Markdown parser handles content with no H1 title
  def test_content_without_h1_title
    content_no_title = <<~MARKDOWN
      This is content without an H1 title.

      **Conference:** Test Conference
    MARKDOWN

    title = @parser.send(:extract_title_from_content, content_no_title)
    assert_equal 'Untitled Talk', title
  end

  # TS-235: Markdown parser handles content with multiple H1 titles
  def test_content_with_multiple_h1_titles
    content_multiple_titles = <<~MARKDOWN
      # First Title

      Some content

      # Second Title
    MARKDOWN

    title = @parser.send(:extract_title_from_content, content_multiple_titles)
    assert_equal 'First Title', title, 'Should extract the first H1 title'
  end
end
