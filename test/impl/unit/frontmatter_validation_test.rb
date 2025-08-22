# frozen_string_literal: true

require 'minitest/autorun'
require 'set'

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

  # Interface class - connected to implementation
  class FrontmatterValidator
    def initialize
      @registered_slugs = Set.new
    end

    def validate_slug(slug)
      errors = []
      
      if slug.nil? || slug.empty?
        errors << "Slug is required"
      elsif slug.length < 3
        errors << "Slug must be at least 3 characters"
      elsif slug.length > 50
        errors << "Slug must be no more than 50 characters"
      elsif !slug.match?(/^[a-z0-9-]+$/)
        errors << "Slug must contain only lowercase letters, numbers, and hyphens"
      elsif @registered_slugs.include?(slug)
        errors << "Slug must be unique across all talks"
      end
      
      ValidationResult.new(errors.empty?, errors)
    end

    def validate_title(title)
      errors = []
      
      if title.nil? || title.empty?
        errors << "Title is required"
      elsif title.length > 200
        errors << "Title must be 200 characters or less"
      end
      
      ValidationResult.new(errors.empty?, errors)
    end

    def validate_speaker(speaker)
      errors = []
      
      if speaker.nil? || speaker.empty?
        errors << "Speaker is required"
      elsif speaker.length > 100
        errors << "Speaker must be no more than 100 characters"
      end
      
      ValidationResult.new(errors.empty?, errors)
    end

    def validate_conference(conference)
      errors = []
      
      if conference.nil? || conference.empty?
        errors << "Conference is required"
      elsif conference.length > 100
        errors << "Conference must be 100 characters or less"
      end
      
      ValidationResult.new(errors.empty?, errors)
    end

    def validate_date(date)
      errors = []
      
      if date.nil? || date.empty?
        errors << "Date is required"
      elsif !date.match?(/^\d{4}-\d{2}-\d{2}$/)
        errors << "Date must be in YYYY-MM-DD format"
      else
        # Additional date validation
        year, month, day = date.split('-').map(&:to_i)
        if month < 1 || month > 12 || day < 1 || day > 31
          errors << "Date must be a valid calendar date"
        end
      end
      
      ValidationResult.new(errors.empty?, errors)
    end

    def validate_status(status)
      errors = []
      valid_statuses = ['upcoming', 'completed', 'in-progress']
      
      if status.nil? || status.empty?
        errors << "Status is required"
      elsif !valid_statuses.include?(status)
        errors << "Status must be one of: #{valid_statuses.join(', ')}"
      end
      
      ValidationResult.new(errors.empty?, errors)
    end

    def validate_optional_fields(fields)
      errors = []
      
      fields.each do |field, value|
        next if value.nil? || value.empty?
        
        case field
        when 'description'
          errors.concat(validate_description(value).errors)
        when 'abstract'
          errors.concat(validate_abstract(value).errors)
        when 'location'
          errors.concat(validate_location(value).errors)
        when 'level'
          errors.concat(validate_level(value).errors)
        end
      end
      
      ValidationResult.new(errors.empty?, errors)
    end

    def validate_location(location)
      errors = []
      
      if location && location.length > 200
        errors << "Location must be no more than 200 characters"
      end
      
      ValidationResult.new(errors.empty?, errors)
    end

    def validate_description(description)
      errors = []
      
      if description && description.length > 500
        errors << "Description must be no more than 500 characters"
      end
      
      ValidationResult.new(errors.empty?, errors)
    end

    def validate_abstract(abstract)
      errors = []
      
      if abstract && abstract.length > 500
        errors << "Abstract must be no more than 500 characters"
      end
      
      ValidationResult.new(errors.empty?, errors)
    end

    def validate_level(level)
      errors = []
      valid_levels = ['beginner', 'intermediate', 'advanced']
      
      if level && !valid_levels.include?(level)
        errors << "Level must be one of: #{valid_levels.join(', ')}"
      end
      
      ValidationResult.new(errors.empty?, errors)
    end

    def validate_all(data)
      all_errors = []
      
      # Validate required fields
      all_errors.concat(validate_title(data['title']).errors)
      all_errors.concat(validate_speaker(data['speaker']).errors)
      all_errors.concat(validate_conference(data['conference']).errors)
      all_errors.concat(validate_date(data['date']).errors)
      all_errors.concat(validate_status(data['status']).errors)
      
      # Validate optional fields if present
      optional_fields = data.select { |k, v| ['description', 'abstract', 'location', 'level'].include?(k) }
      all_errors.concat(validate_optional_fields(optional_fields).errors)
      
      ValidationResult.new(all_errors.empty?, all_errors)
    end

    def register_slug(slug)
      @registered_slugs.add(slug)
    end
  end

  # Interface class for validation results
  class ValidationResult
    def initialize(valid, errors)
      @valid = valid
      @errors = errors
    end
    
    def valid?
      @valid
    end

    def errors
      @errors
    end
  end
end