# frozen_string_literal: true

require 'minitest/autorun'

# Unit tests for Frontmatter Validation (TS-076 through TS-085)
# Maps to Gherkin: "Talk frontmatter validates required fields correctly" + "Talk frontmatter handles optional fields correctly"
class FrontmatterValidationTest < Minitest::Test
  def setup
    @valid_required_fields = {
      'slug' => 'unique-talk-identifier',
      'title' => 'Valid Title',
      'speaker' => 'Jane Developer',
      'conference' => 'JSConf 2024',
      'date' => '2024-03-15',
      'status' => 'completed'
    }

    @valid_optional_fields = {
      'location' => 'San Francisco, CA',
      'description' => 'A talk about modern web development',
      'abstract' => 'This is a longer abstract that provides more detail about the talk content.',
      'duration' => '45 minutes',
      'level' => 'intermediate',
      'topics' => ['javascript', 'web-development']
    }
  end

  # TS-076: Talk has unique identifier (slug)
  def test_slug_uniqueness_validation
    validator = FrontmatterValidator.new
    
    # Valid unique slug should pass
    result = validator.validate_slug('unique-identifier-123')
    assert result.valid?, 'Valid unique slug should pass validation'
    
    # Duplicate slug should fail
    validator.register_slug('existing-slug')
    result = validator.validate_slug('existing-slug')
    refute result.valid?, 'Duplicate slug should fail validation'
    assert_includes result.errors, 'Slug must be unique across all talks'
  end

  # TS-077: Title is present and within 200 characters
  def test_title_validation
    validator = FrontmatterValidator.new
    
    # Valid title should pass
    result = validator.validate_title('Valid Title')
    assert result.valid?, 'Valid title should pass validation'
    
    # Missing title should fail
    result = validator.validate_title(nil)
    refute result.valid?, 'Missing title should fail validation'
    
    # Title over 200 characters should fail
    long_title = 'a' * 201
    result = validator.validate_title(long_title)
    refute result.valid?, 'Title over 200 characters should fail validation'
    assert_includes result.errors, 'Title must be 200 characters or less'
  end

  # TS-078: Speaker name is present and within 100 characters
  def test_speaker_validation
    validator = FrontmatterValidator.new
    
    # Valid speaker should pass
    result = validator.validate_speaker('Jane Developer')
    assert result.valid?, 'Valid speaker name should pass validation'
    
    # Missing speaker should fail
    result = validator.validate_speaker('')
    refute result.valid?, 'Empty speaker name should fail validation'
    
    # Speaker over 100 characters should fail
    long_speaker = 'a' * 101
    result = validator.validate_speaker(long_speaker)
    refute result.valid?, 'Speaker over 100 characters should fail validation'
  end

  # TS-079: Conference name is present and within 100 characters
  def test_conference_validation
    validator = FrontmatterValidator.new
    
    # Valid conference should pass
    result = validator.validate_conference('JSConf 2024')
    assert result.valid?, 'Valid conference name should pass validation'
    
    # Missing conference should fail
    result = validator.validate_conference(nil)
    refute result.valid?, 'Missing conference should fail validation'
    
    # Conference over 100 characters should fail
    long_conference = 'a' * 101
    result = validator.validate_conference(long_conference)
    refute result.valid?, 'Conference over 100 characters should fail validation'
  end

  # TS-080: Date follows ISO 8601 format
  def test_date_format_validation
    validator = FrontmatterValidator.new
    
    # Valid ISO 8601 date should pass
    result = validator.validate_date('2024-03-15')
    assert result.valid?, 'Valid ISO 8601 date should pass validation'
    
    # Invalid date format should fail
    result = validator.validate_date('March 15, 2024')
    refute result.valid?, 'Non-ISO date format should fail validation'
    
    result = validator.validate_date('2024/03/15')
    refute result.valid?, 'Slash-separated date should fail validation'
    
    # Invalid date should fail
    result = validator.validate_date('2024-13-32')
    refute result.valid?, 'Invalid date should fail validation'
  end

  # TS-081: Status is valid enum value
  def test_status_enum_validation
    validator = FrontmatterValidator.new
    
    # Valid status values should pass
    %w[upcoming completed in-progress].each do |status|
      result = validator.validate_status(status)
      assert result.valid?, "Status '#{status}' should be valid"
    end
    
    # Invalid status should fail
    result = validator.validate_status('invalid-status')
    refute result.valid?, 'Invalid status should fail validation'
    assert_includes result.errors, 'Status must be one of: upcoming, completed, in-progress'
  end

  # TS-082: Optional fields validate when present
  def test_optional_fields_validation_when_present
    validator = FrontmatterValidator.new
    
    # Valid optional fields should pass
    result = validator.validate_optional_fields(@valid_optional_fields)
    assert result.valid?, 'Valid optional fields should pass validation'
  end

  # TS-083: Missing optional fields don't break rendering
  def test_missing_optional_fields_handled
    validator = FrontmatterValidator.new
    
    # Completely missing optional fields should not cause errors
    result = validator.validate_optional_fields({})
    assert result.valid?, 'Missing optional fields should not cause validation errors'
    
    # Partially missing optional fields should not cause errors
    partial_fields = { 'location' => 'Test Location' }
    result = validator.validate_optional_fields(partial_fields)
    assert result.valid?, 'Partially missing optional fields should not cause errors'
  end

  # TS-084: Field length limits are enforced
  def test_optional_field_length_limits
    validator = FrontmatterValidator.new
    
    # Location over 200 characters should fail
    long_location = 'a' * 201
    result = validator.validate_location(long_location)
    refute result.valid?, 'Location over 200 characters should fail'
    
    # Description over 500 characters should fail
    long_description = 'a' * 501
    result = validator.validate_description(long_description)
    refute result.valid?, 'Description over 500 characters should fail'
    
    # Abstract over 2000 characters should fail
    long_abstract = 'a' * 2001
    result = validator.validate_abstract(long_abstract)
    refute result.valid?, 'Abstract over 2000 characters should fail'
  end

  # TS-085: Enum values are validated
  def test_optional_enum_validation
    validator = FrontmatterValidator.new
    
    # Valid level values should pass
    %w[beginner intermediate advanced].each do |level|
      result = validator.validate_level(level)
      assert result.valid?, "Level '#{level}' should be valid"
    end
    
    # Invalid level should fail
    result = validator.validate_level('expert')
    refute result.valid?, 'Invalid level should fail validation'
  end

  # Integration test for complete frontmatter validation
  def test_complete_frontmatter_validation
    validator = FrontmatterValidator.new
    complete_data = @valid_required_fields.merge(@valid_optional_fields)
    
    result = validator.validate_all(complete_data)
    assert result.valid?, 'Complete valid frontmatter should pass validation'
    
    # Test with missing required field
    incomplete_data = complete_data.dup
    incomplete_data.delete('title')
    
    result = validator.validate_all(incomplete_data)
    refute result.valid?, 'Frontmatter missing required field should fail validation'
    assert_includes result.errors, 'Title is required'
  end

  private

  # Interface class - implementation will be created later
  class FrontmatterValidator
    def initialize
      fail 'FrontmatterValidator class not implemented yet'
    end

    def validate_slug(slug)
      fail 'validate_slug method not implemented yet'
    end

    def validate_title(title)
      fail 'validate_title method not implemented yet'
    end

    def validate_speaker(speaker)
      fail 'validate_speaker method not implemented yet'
    end

    def validate_conference(conference)
      fail 'validate_conference method not implemented yet'
    end

    def validate_date(date)
      fail 'validate_date method not implemented yet'
    end

    def validate_status(status)
      fail 'validate_status method not implemented yet'
    end

    def validate_optional_fields(fields)
      fail 'validate_optional_fields method not implemented yet'
    end

    def validate_location(location)
      fail 'validate_location method not implemented yet'
    end

    def validate_description(description)
      fail 'validate_description method not implemented yet'
    end

    def validate_abstract(abstract)
      fail 'validate_abstract method not implemented yet'
    end

    def validate_level(level)
      fail 'validate_level method not implemented yet'
    end

    def validate_all(data)
      fail 'validate_all method not implemented yet'
    end

    def register_slug(slug)
      fail 'register_slug method not implemented yet'
    end
  end

  # Interface class for validation results
  class ValidationResult
    def valid?
      fail 'ValidationResult#valid? method not implemented yet'
    end

    def errors
      fail 'ValidationResult#errors method not implemented yet'
    end
  end
end