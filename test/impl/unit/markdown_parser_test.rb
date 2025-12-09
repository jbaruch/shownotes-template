require 'minitest/autorun'
require 'jekyll'
require_relative '../../../_plugins/markdown_parser'

class MarkdownParserTest < Minitest::Test
  def setup
    @processor = Jekyll::MarkdownTalkProcessor.new
  end

  def test_extract_title_from_content_with_valid_h1
    content = "# My Amazing Talk\n\n**Conference:** DevConf"
    title = @processor.send(:extract_title_from_content, content)
    assert_equal 'My Amazing Talk', title
  end

  def test_extract_title_handles_missing_h1
    content = "**Conference:** DevConf"
    title = @processor.send(:extract_title_from_content, content)
    assert_equal 'Untitled Talk', title
  end

  def test_extract_title_handles_empty_h1
    content = "# \n\n**Conference:** DevConf"
    title = @processor.send(:extract_title_from_content, content)
    assert_equal 'Untitled Talk', title
  end

  def test_extract_title_handles_nil_content
    title = @processor.send(:extract_title_from_content, nil)
    assert_equal 'Untitled Talk', title
  end

  def test_extract_metadata_from_content_conference
    content = "# Talk\n\n**Conference:** DevConf 2025"
    conference = @processor.send(:extract_metadata_from_content, content, 'conference')
    assert_equal 'DevConf 2025', conference
  end

  def test_extract_metadata_from_content_date
    content = "# Talk\n\n**Date:** 2025-10-01"
    date = @processor.send(:extract_metadata_from_content, content, 'date')
    assert_equal '2025-10-01', date
  end

  def test_extract_metadata_from_content_with_link
    content = "# Talk\n\n**Slides:** [View Slides](https://example.com/slides)"
    slides = @processor.send(:extract_metadata_from_content, content, 'slides')
    assert_equal 'https://example.com/slides', slides
  end

  def test_extract_metadata_from_content_with_plain_url
    content = "# Talk\n\n**Video:** https://youtube.com/watch"
    video = @processor.send(:extract_metadata_from_content, content, 'video')
    assert_equal 'https://youtube.com/watch', video
  end

  def test_extract_metadata_handles_missing_field
    content = "# Talk\n\n**Conference:** DevConf"
    slides = @processor.send(:extract_metadata_from_content, content, 'slides')
    assert_nil slides
  end

  def test_extract_metadata_handles_nil_content
    result = @processor.send(:extract_metadata_from_content, nil, 'conference')
    assert_nil result
  end

  def test_extract_abstract_from_content
    content = <<~MARKDOWN
      # Talk Title
      
      **Conference:** DevConf
      
      A presentation at DevConf 2025
      
      ## Abstract
      
      This is the abstract content.
      It spans multiple lines.
      
      ## Resources
      
      - Link 1
    MARKDOWN
    
    abstract = @processor.send(:extract_abstract_from_content, content)
    assert_includes abstract, 'This is the abstract content'
    assert_includes abstract, 'It spans multiple lines'
    refute_includes abstract, 'Resources'
  end

  def test_extract_abstract_handles_missing_section
    content = "# Talk\n\n**Conference:** DevConf"
    abstract = @processor.send(:extract_abstract_from_content, content)
    assert_equal '', abstract
  end

  def test_extract_resources_from_content
    content = <<~MARKDOWN
      # Talk Title
      
      ## Abstract
      
      Some abstract
      
      ## Resources
      
      - [Resource 1](https://example.com/1)
      - [Resource 2](https://example.com/2)
    MARKDOWN
    
    resources = @processor.send(:extract_resources_from_content, content)
    assert_includes resources, 'Resource 1'
    assert_includes resources, 'Resource 2'
    assert_includes resources, 'https://example.com/1'
  end

  def test_extract_resources_handles_missing_section
    content = "# Talk\n\n**Conference:** DevConf"
    resources = @processor.send(:extract_resources_from_content, content)
    assert_equal '', resources
  end

  def test_extract_resources_handles_nil_content
    resources = @processor.send(:extract_resources_from_content, nil)
    assert_equal '', resources
  end

  def test_extract_description_from_content
    content = <<~MARKDOWN
      # Talk Title
      
      **Conference:** DevConf
      **Date:** 2025-10-01
      
      A presentation at DevConf 2025
      
      ## Abstract
      
      This is the abstract content that should be extracted.
      
      ## Resources
      
      - Link 1
    MARKDOWN
    
    description = @processor.send(:extract_description_from_content, content)
    # Description extraction falls back to abstract if no description paragraph
    assert_includes description, 'abstract content'
  end

  def test_extract_description_handles_nil_content
    description = @processor.send(:extract_description_from_content, nil)
    assert_equal '', description
  end
end
