# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/utils/filename_generator'

class FilenameGeneratorTest < Minitest::Test
  include FilenameGenerator
  
  # Test generate_slug method
  
  def test_generate_slug_basic
    assert_equal 'hello-world', generate_slug('Hello World')
    assert_equal 'test-slug', generate_slug('Test Slug')
  end
  
  def test_generate_slug_removes_special_characters
    assert_equal 'hello-world', generate_slug('Hello & World!')
    assert_equal 'test-123', generate_slug('Test @#$ 123')
  end
  
  def test_generate_slug_handles_multiple_spaces
    assert_equal 'hello-world', generate_slug('Hello    World')
    assert_equal 'test-slug', generate_slug('Test   Slug')
  end
  
  def test_generate_slug_with_max_length
    long_text = 'This is a very long title that should be truncated'
    result = generate_slug(long_text, max_length: 20)
    assert result.length <= 20
    refute result.end_with?('-')
  end
  
  def test_generate_slug_preserves_numbers
    assert_equal 'devconf-2024', generate_slug('DevConf 2024')
    assert_equal 'talk-123-test', generate_slug('Talk 123 Test')
  end
  
  def test_generate_slug_handles_empty_string
    assert_equal '', generate_slug('')
    assert_equal '', generate_slug('   ')
  end
  
  def test_generate_slug_handles_nil
    assert_equal '', generate_slug(nil)
  end
  
  # Test generate_conference_slug method
  
  def test_generate_conference_slug_removes_common_words
    assert_equal 'devops-2024', generate_conference_slug('DevOps Conference 2024')
    assert_equal 'devoxx', generate_conference_slug('Devoxx Developer Summit')
  end
  
  def test_generate_conference_slug_keeps_location
    assert_equal 'devops-nashville', generate_conference_slug('DevOps Nashville 2024')
    assert_equal 'javaland', generate_conference_slug('JavaLand Conference')
  end
  
  def test_generate_conference_slug_limits_parts
    result = generate_conference_slug('International World Technology Developer Conference Summit 2024')
    parts = result.split('-')
    assert parts.length <= 3
  end
  
  def test_generate_conference_slug_handles_short_names
    assert_equal 'kcdc-2024', generate_conference_slug('KCDC 2024')
    assert_equal 'api', generate_conference_slug('API Conference')
  end
  
  # Test generate_title_slug method
  
  def test_generate_title_slug_removes_stop_words
    assert_equal 'coding-fast-slow', generate_title_slug('Coding Fast and Slow')
    assert_equal 'devops-reframed', generate_title_slug('DevOps Reframed')
  end
  
  def test_generate_title_slug_keeps_technical_terms
    assert_equal 'kubernetes-production', generate_title_slug('Kubernetes in Production')
    assert_equal 'microservices-architecture', generate_title_slug('Microservices Architecture')
  end
  
  def test_generate_title_slug_handles_short_titles
    assert_equal 'testing', generate_title_slug('Testing')
    assert_equal 'api-design', generate_title_slug('API Design')
  end
  
  def test_generate_title_slug_with_max_length
    long_title = 'This is a Very Long Title About Software Development Best Practices'
    result = generate_title_slug(long_title, max_length: 30)
    assert result.length <= 30
  end
  
  # Test generate_talk_filename method
  
  def test_generate_talk_filename_basic
    filename = generate_talk_filename('2024-12-04', 'DevConf 2024', 'Coding Fast and Slow')
    assert filename.start_with?('2024-12-04-')
    assert filename.end_with?('.md')
    assert filename.include?('devconf')
    assert filename.include?('coding')
  end
  
  def test_generate_talk_filename_with_complex_conference
    filename = generate_talk_filename('2024-06-12', 'DevOps Nashville Conference 2024', 'Test Talk')
    assert_equal '2024-06-12-devops-nashville-test-talk.md', filename
  end
  
  def test_generate_talk_filename_reasonable_length
    filename = generate_talk_filename(
      '2024-12-04',
      'International Technology Conference',
      'A Very Long Talk Title About Software Development'
    )
    assert filename.length < 100  # Reasonable filename length
  end
  
  def test_generate_talk_filename_no_extension
    filename = generate_talk_filename('2024-12-04', 'DevConf', 'Test', extension: '')
    refute filename.end_with?('.md')
    assert_equal '2024-12-04-devconf-test', filename
  end
  
  def test_generate_talk_filename_custom_extension
    filename = generate_talk_filename('2024-12-04', 'DevConf', 'Test', extension: '.html')
    assert filename.end_with?('.html')
  end
  
  # Test generate_thumbnail_filename method
  
  def test_generate_thumbnail_filename_from_talk_slug
    filename = generate_thumbnail_filename('2024-12-04-devconf-coding-fast')
    assert_equal '2024-12-04-devconf-coding-fast-thumbnail.png', filename
  end
  
  def test_generate_thumbnail_filename_from_components
    filename = generate_thumbnail_filename({
      date: '2024-12-04',
      conference: 'DevConf',
      title: 'Coding Fast'
    })
    assert filename.start_with?('2024-12-04-')
    assert filename.end_with?('-thumbnail.png')
  end
  
  def test_generate_thumbnail_filename_custom_extension
    filename = generate_thumbnail_filename('test-talk', extension: '.jpg')
    assert_equal 'test-talk-thumbnail.jpg', filename
  end
  
  # Test sanitize_filename method
  
  def test_sanitize_filename_removes_invalid_characters
    assert_equal 'test-file', sanitize_filename('test/file')
    assert_equal 'test-file', sanitize_filename('test\\file')
    assert_equal 'test-file', sanitize_filename('test:file')
  end
  
  def test_sanitize_filename_preserves_valid_characters
    assert_equal 'test-file-123.txt', sanitize_filename('test-file-123.txt')
    assert_equal 'my_file.pdf', sanitize_filename('my_file.pdf')
  end
  
  def test_sanitize_filename_handles_multiple_invalid_chars
    assert_equal 'test-file', sanitize_filename('test///file')
    assert_equal 'test-file', sanitize_filename('test***file')
  end
end
