# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../../lib/talk_renderer'

# Tests for TalkRenderer URL validation and detection
class TalkRendererUrlValidationTest < Minitest::Test
  def setup
    @renderer = TalkRenderer.new
  end

  # embeddable_url? tests
  def test_embeddable_url_returns_false_for_nil
    refute @renderer.embeddable_url?(nil)
  end

  def test_embeddable_url_returns_false_for_empty_string
    refute @renderer.embeddable_url?('')
  end

  def test_embeddable_url_returns_true_for_google_slides
    assert @renderer.embeddable_url?('https://docs.google.com/presentation/d/abc123/edit')
  end

  def test_embeddable_url_returns_true_for_youtube
    assert @renderer.embeddable_url?('https://www.youtube.com/watch?v=abc123')
  end

  def test_embeddable_url_returns_false_for_regular_url
    refute @renderer.embeddable_url?('https://example.com')
  end

  # google_slides_url? tests
  def test_google_slides_url_detects_standard_format
    assert @renderer.google_slides_url?('https://docs.google.com/presentation/d/abc123/edit')
  end

  def test_google_slides_url_detects_view_format
    assert @renderer.google_slides_url?('https://docs.google.com/presentation/d/abc123/view')
  end

  def test_google_slides_url_detects_present_format
    assert @renderer.google_slides_url?('https://docs.google.com/presentation/d/abc123/present')
  end

  def test_google_slides_url_rejects_non_slides_url
    refute @renderer.google_slides_url?('https://docs.google.com/document/d/abc123')
  end

  def test_google_slides_url_rejects_regular_url
    refute @renderer.google_slides_url?('https://example.com')
  end

  # youtube_url? tests
  def test_youtube_url_detects_standard_watch_format
    assert @renderer.youtube_url?('https://www.youtube.com/watch?v=abc123')
  end

  def test_youtube_url_detects_short_format
    assert @renderer.youtube_url?('https://youtu.be/abc123')
  end

  def test_youtube_url_detects_mobile_format
    assert @renderer.youtube_url?('https://m.youtube.com/watch?v=abc123')
  end

  def test_youtube_url_detects_with_additional_parameters
    assert @renderer.youtube_url?('https://www.youtube.com/watch?v=abc123&t=30s')
  end

  def test_youtube_url_rejects_non_youtube_url
    refute @renderer.youtube_url?('https://vimeo.com/123456')
  end

  def test_youtube_url_rejects_regular_url
    refute @renderer.youtube_url?('https://example.com')
  end

  # extract_youtube_video_id tests
  def test_extract_youtube_video_id_from_standard_format
    video_id = @renderer.extract_youtube_video_id('https://www.youtube.com/watch?v=dQw4w9WgXcQ')
    assert_equal 'dQw4w9WgXcQ', video_id
  end

  def test_extract_youtube_video_id_from_short_format
    video_id = @renderer.extract_youtube_video_id('https://youtu.be/dQw4w9WgXcQ')
    assert_equal 'dQw4w9WgXcQ', video_id
  end

  def test_extract_youtube_video_id_from_mobile_format
    video_id = @renderer.extract_youtube_video_id('https://m.youtube.com/watch?v=dQw4w9WgXcQ')
    assert_equal 'dQw4w9WgXcQ', video_id
  end

  def test_extract_youtube_video_id_with_additional_parameters
    video_id = @renderer.extract_youtube_video_id('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30s')
    assert_equal 'dQw4w9WgXcQ', video_id
  end

  def test_extract_youtube_video_id_from_short_format_with_parameters
    video_id = @renderer.extract_youtube_video_id('https://youtu.be/dQw4w9WgXcQ?t=30')
    assert_equal 'dQw4w9WgXcQ', video_id
  end

  def test_extract_youtube_video_id_returns_nil_for_invalid_url
    video_id = @renderer.extract_youtube_video_id('https://example.com')
    assert_nil video_id
  end

  def test_extract_youtube_video_id_handles_video_id_with_underscores
    video_id = @renderer.extract_youtube_video_id('https://www.youtube.com/watch?v=abc_123-XYZ')
    assert_equal 'abc_123-XYZ', video_id
  end

  # convert_to_embed_url tests
  def test_convert_to_embed_url_converts_google_slides
    original = 'https://docs.google.com/presentation/d/abc123/edit'
    embed = @renderer.convert_to_embed_url(original)
    assert_includes embed, 'pubembed'
    assert_includes embed, 'abc123'
  end

  def test_convert_to_embed_url_converts_youtube
    original = 'https://www.youtube.com/watch?v=abc123'
    embed = @renderer.convert_to_embed_url(original)
    assert_equal 'https://www.youtube.com/embed/abc123', embed
  end

  def test_convert_to_embed_url_returns_original_for_non_embeddable
    original = 'https://example.com'
    embed = @renderer.convert_to_embed_url(original)
    assert_equal original, embed
  end

  # convert_google_slides_to_embed tests
  def test_convert_google_slides_to_embed_standard_format
    original = 'https://docs.google.com/presentation/d/1abc123xyz/edit'
    embed = @renderer.convert_google_slides_to_embed(original)
    assert_equal 'https://docs.google.com/presentation/d/e/1abc123xyz/pubembed?start=false&loop=false&delayms=3000', embed
  end

  def test_convert_google_slides_to_embed_with_hyphens_and_underscores
    original = 'https://docs.google.com/presentation/d/abc-123_XYZ/edit'
    embed = @renderer.convert_google_slides_to_embed(original)
    assert_includes embed, 'abc-123_XYZ'
  end

  def test_convert_google_slides_to_embed_returns_original_if_no_match
    original = 'https://docs.google.com/document/d/abc123'
    embed = @renderer.convert_google_slides_to_embed(original)
    assert_equal original, embed
  end

  # convert_youtube_to_embed tests
  def test_convert_youtube_to_embed_standard_format
    original = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
    embed = @renderer.convert_youtube_to_embed(original)
    assert_equal 'https://www.youtube.com/embed/dQw4w9WgXcQ', embed
  end

  def test_convert_youtube_to_embed_short_format
    original = 'https://youtu.be/dQw4w9WgXcQ'
    embed = @renderer.convert_youtube_to_embed(original)
    assert_equal 'https://www.youtube.com/embed/dQw4w9WgXcQ', embed
  end

  def test_convert_youtube_to_embed_returns_original_if_no_video_id
    original = 'https://www.youtube.com/channel/abc123'
    embed = @renderer.convert_youtube_to_embed(original)
    assert_equal original, embed
  end

  # Edge cases
  def test_handles_url_with_special_characters_in_path
    url = 'https://docs.google.com/presentation/d/abc-123_XYZ-456/edit?usp=sharing'
    assert @renderer.google_slides_url?(url)
  end

  def test_handles_youtube_url_with_playlist_parameter
    url = 'https://www.youtube.com/watch?v=abc123&list=PLxyz'
    video_id = @renderer.extract_youtube_video_id(url)
    assert_equal 'abc123', video_id
  end

  def test_rejects_malformed_google_slides_url
    url = 'https://docs.google.com/presentation/abc123'
    refute @renderer.google_slides_url?(url)
  end

  def test_rejects_malformed_youtube_url
    url = 'https://www.youtube.com/abc123'
    refute @renderer.youtube_url?(url)
  end
end
