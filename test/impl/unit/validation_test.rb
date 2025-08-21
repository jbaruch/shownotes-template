# frozen_string_literal: true

require 'minitest/autorun'

# Unit tests for Data Validation (TS-086 through TS-121)
# Maps to remaining validation scenarios from test scenarios document
class ValidationTest < Minitest::Test
  def setup
    @valid_talk = {
      'title' => 'Valid Test Talk',
      'speaker' => 'Test Speaker',
      'conference' => 'Test Conference',
      'date' => '2024-03-15',
      'status' => 'completed'
    }
  end

  # TS-086: Talk title validation (length, characters)
  def test_talk_title_validation
    # Valid titles
    valid_titles = [
      'Short Title',
      'A Moderately Long Title That Should Pass Validation',
      'Title with Numbers 123 and Symbols: Modern Web!'
    ]
    
    valid_titles.each do |title|
      talk = @valid_talk.merge('title' => title)
      result = validate_talk_data(talk)
      assert result[:valid], "Title '#{title}' should be valid"
    end
    
    # Invalid titles
    invalid_titles = [
      '', # Empty
      'x' * 201, # Too long (over 200 chars)
      nil # Nil value
    ]
    
    invalid_titles.each do |title|
      talk = @valid_talk.merge('title' => title)
      result = validate_talk_data(talk)
      refute result[:valid], "Title '#{title}' should be invalid"
      assert_includes result[:errors].join(' '), 'title'
    end
  end

  # TS-087: Speaker name validation
  def test_speaker_name_validation
    # Valid speakers
    valid_speakers = [
      'John Doe',
      'María García-Rodriguez',
      'Dr. Jane Smith, PhD',
      'Jean-Luc O\'Connor'
    ]
    
    valid_speakers.each do |speaker|
      talk = @valid_talk.merge('speaker' => speaker)
      result = validate_talk_data(talk)
      assert result[:valid], "Speaker '#{speaker}' should be valid"
    end
    
    # Invalid speakers
    invalid_speakers = [
      '', # Empty
      'x' * 101, # Too long (over 100 chars)
      nil # Nil value
    ]
    
    invalid_speakers.each do |speaker|
      talk = @valid_talk.merge('speaker' => speaker)
      result = validate_talk_data(talk)
      refute result[:valid], "Speaker '#{speaker}' should be invalid"
    end
  end

  # TS-088: Date format validation (ISO 8601)
  def test_date_format_validation
    # Valid dates
    valid_dates = [
      '2024-01-15',
      '2024-12-31',
      '2023-02-28'
    ]
    
    valid_dates.each do |date|
      talk = @valid_talk.merge('date' => date)
      result = validate_talk_data(talk)
      assert result[:valid], "Date '#{date}' should be valid"
    end
    
    # Invalid dates
    invalid_dates = [
      '2024/01/15', # Wrong format
      '15-01-2024', # Wrong order
      '2024-13-01', # Invalid month
      '2024-01-32', # Invalid day
      'not-a-date', # Not a date
      '', # Empty
      nil # Nil
    ]
    
    invalid_dates.each do |date|
      talk = @valid_talk.merge('date' => date)
      result = validate_talk_data(talk)
      refute result[:valid], "Date '#{date}' should be invalid"
    end
  end

  # TS-089: Status enumeration validation
  def test_status_enumeration_validation
    # Valid statuses
    valid_statuses = %w[upcoming completed cancelled postponed]
    
    valid_statuses.each do |status|
      talk = @valid_talk.merge('status' => status)
      result = validate_talk_data(talk)
      assert result[:valid], "Status '#{status}' should be valid"
    end
    
    # Invalid statuses
    invalid_statuses = ['invalid', 'COMPLETED', 'unknown', '', nil]
    
    invalid_statuses.each do |status|
      talk = @valid_talk.merge('status' => status)
      result = validate_talk_data(talk)
      refute result[:valid], "Status '#{status}' should be invalid"
    end
  end

  # TS-090: URL validation for resources
  def test_url_validation_for_resources
    # Valid URLs
    valid_urls = [
      'https://example.com',
      'http://slides.conference.org/path',
      'https://github.com/user/repo',
      'https://www.youtube.com/watch?v=123'
    ]
    
    valid_urls.each do |url|
      talk = @valid_talk.merge(
        'resources' => {
          'slides' => { 'url' => url, 'title' => 'Test' }
        }
      )
      result = validate_talk_data(talk)
      assert result[:valid], "URL '#{url}' should be valid"
    end
    
    # Invalid URLs
    invalid_urls = [
      'not-a-url',
      'ftp://old.protocol.com',
      'javascript:alert(1)',
      '',
      'http://', # Incomplete
      'https://space in url.com'
    ]
    
    invalid_urls.each do |url|
      talk = @valid_talk.merge(
        'resources' => {
          'slides' => { 'url' => url, 'title' => 'Test' }
        }
      )
      result = validate_talk_data(talk)
      refute result[:valid], "URL '#{url}' should be invalid"
    end
  end

  # TS-091: Conference name validation
  def test_conference_name_validation
    # Valid conference names
    valid_conferences = [
      'JSConf 2024',
      'React Europe 2023',
      'Local JavaScript Meetup #45',
      'PyCon US 2024'
    ]
    
    valid_conferences.each do |conference|
      talk = @valid_talk.merge('conference' => conference)
      result = validate_talk_data(talk)
      assert result[:valid], "Conference '#{conference}' should be valid"
    end
    
    # Invalid conferences
    invalid_conferences = ['', 'x' * 151, nil]
    
    invalid_conferences.each do |conference|
      talk = @valid_talk.merge('conference' => conference)
      result = validate_talk_data(talk)
      refute result[:valid], "Conference '#{conference}' should be invalid"
    end
  end

  # TS-092: Description length validation
  def test_description_length_validation
    # Valid descriptions
    short_description = 'A brief overview of the topic.'
    long_description = 'This is a comprehensive description that provides detailed information about the talk content, covering all the main points that will be discussed during the presentation.'
    
    [short_description, long_description].each do |description|
      talk = @valid_talk.merge('description' => description)
      result = validate_talk_data(talk)
      assert result[:valid], "Description should be valid"
    end
    
    # Invalid description (too long)
    too_long_description = 'x' * 1001 # Over 1000 chars
    talk = @valid_talk.merge('description' => too_long_description)
    result = validate_talk_data(talk)
    refute result[:valid], "Overly long description should be invalid"
  end

  # TS-093: Resource title validation
  def test_resource_title_validation
    # Valid resource titles
    valid_titles = ['Slides', 'GitHub Repository', 'Demo Video']
    
    valid_titles.each do |title|
      talk = @valid_talk.merge(
        'resources' => {
          'slides' => { 
            'title' => title,
            'url' => 'https://example.com'
          }
        }
      )
      result = validate_talk_data(talk)
      assert result[:valid], "Resource title '#{title}' should be valid"
    end
    
    # Invalid resource titles
    invalid_titles = ['', 'x' * 101, nil]
    
    invalid_titles.each do |title|
      talk = @valid_talk.merge(
        'resources' => {
          'slides' => {
            'title' => title,
            'url' => 'https://example.com'
          }
        }
      )
      result = validate_talk_data(talk)
      refute result[:valid], "Resource title '#{title}' should be invalid"
    end
  end

  # TS-094: Topics array validation
  def test_topics_array_validation
    # Valid topics
    valid_topics = [
      ['javascript', 'react'],
      ['web development', 'performance'],
      ['testing', 'automation', 'ci/cd']
    ]
    
    valid_topics.each do |topics|
      talk = @valid_talk.merge('topics' => topics)
      result = validate_talk_data(talk)
      assert result[:valid], "Topics #{topics} should be valid"
    end
    
    # Invalid topics
    invalid_topic_sets = [
      [''], # Empty string in array
      ['x' * 51], # Topic too long
      Array.new(21, 'topic'), # Too many topics (over 20)
      'not-an-array' # Not an array
    ]
    
    invalid_topic_sets.each do |topics|
      talk = @valid_talk.merge('topics' => topics)
      result = validate_talk_data(talk)
      refute result[:valid], "Topics #{topics} should be invalid"
    end
  end

  # TS-095: Social media handle validation
  def test_social_media_validation
    # Valid social handles
    valid_social = {
      'twitter' => '@username',
      'github' => 'githubuser',
      'website' => 'https://example.com'
    }
    
    talk = @valid_talk.merge('social' => valid_social)
    result = validate_talk_data(talk)
    assert result[:valid], "Valid social media data should pass validation"
    
    # Invalid social handles
    invalid_social = {
      'twitter' => 'x' * 16, # Too long for Twitter
      'github' => 'invalid user', # Spaces not allowed
      'website' => 'not-a-url'
    }
    
    talk = @valid_talk.merge('social' => invalid_social)
    result = validate_talk_data(talk)
    refute result[:valid], "Invalid social media data should fail validation"
  end

  # TS-096 through TS-121: Additional validation scenarios
  def test_comprehensive_validation_scenarios
    # Test various edge cases and combinations
    edge_cases = [
      # Unicode characters
      {
        'title' => '🎤 Unicode Talk with Emojis 🚀',
        'speaker' => 'François Müller',
        'description' => 'A talk about 国际化 and localization'
      },
      
      # Boundary values
      {
        'title' => 'x' * 200, # Exactly at limit
        'speaker' => 'y' * 100, # Exactly at limit
        'description' => 'z' * 1000 # Exactly at limit
      },
      
      # Complex resources structure
      {
        'resources' => {
          'slides' => {
            'title' => 'Main Slides',
            'url' => 'https://slides.example.com',
            'description' => 'Primary presentation slides'
          },
          'code' => {
            'title' => 'Source Code',
            'url' => 'https://github.com/user/repo'
          },
          'links' => [
            {
              'title' => 'Reference 1',
              'url' => 'https://ref1.example.com',
              'description' => 'Additional reference'
            },
            {
              'title' => 'Reference 2', 
              'url' => 'https://ref2.example.com'
            }
          ]
        }
      }
    ]
    
    edge_cases.each_with_index do |case_data, index|
      talk = @valid_talk.merge(case_data)
      result = validate_talk_data(talk)
      assert result[:valid], "Edge case #{index + 1} should be valid: #{result[:errors]}"
    end
  end

  private

  # Interface method - implementation will be created later
  def validate_talk_data(data)
    fail 'validate_talk_data method not implemented yet'
  end
end