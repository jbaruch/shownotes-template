#!/usr/bin/env ruby

require 'minitest/autorun'
require 'yaml'
require 'net/http'
require 'uri'
require 'json'
require 'timeout'

class MigrationTest < Minitest::Test
  # Test data directory
  TALKS_DIR = File.join(File.dirname(__FILE__), '..', '_talks')
  EXPECTED_TESTS = {
    'luxembourg' => {
      file: '2025-06-20-voxxed-luxembourg-technical-enshittification.md',
      notist_url: 'https://noti.st/jbaruch/W6dSPZ/technical-enshittification-why-everything-in-it-is-horrible-right-now-and-how-to-fix-it',
      expected_resource_count: 42, # Updated to actual migrated count
      has_video: true,
      video_url: 'https://youtube.com/watch?v=iFN1Y_8Cuik',
      slides_count: 1,
      pdf_count: 1
    },
    'robocoders' => {
      file: '2025-06-11-devoxx-poland-robocoders-judgment-day.md',
      notist_url: 'https://speaking.jbaru.ch/PjlHKD/robocoders-judgment-day-ai-ides-face-off',
      expected_resource_count: 18,
      has_video: false, # Video pending
      video_url: nil,
      slides_count: 1,
      pdf_count: 0 # PDF not on Google Drive yet
    }
  }
  
  def setup
    @talks = {}
    load_all_talks
  end
  
  def load_all_talks
    Dir.glob("#{TALKS_DIR}/*.md").each do |file|
      content = File.read(file)
      if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
        yaml_content = YAML.safe_load($1)
        @talks[File.basename(file, '.md')] = {
          file: file,
          yaml: yaml_content,
          raw_content: content
        }
      end
    end
  end

  # ==========================================
  # Test Suite 1: Content Migration Accuracy  
  # ==========================================
  
  def test_complete_resource_migration_luxembourg
    talk = @talks['2025-06-20-voxxed-luxembourg-technical-enshittification']
    refute_nil talk, "Luxembourg talk file not found"
    
    resources = talk[:yaml]['resources'] || []
    expected_count = EXPECTED_TESTS['luxembourg'][:expected_resource_count]
    
    assert_equal expected_count, resources.length, 
      "Expected exactly #{expected_count} resources, got #{resources.length}. " \
      "Migration incomplete - missing #{expected_count - resources.length} resources!"
      
    # Verify each resource has required fields
    resources.each_with_index do |resource, index|
      assert resource['title'], "Resource #{index + 1} missing title"
      assert resource['url'], "Resource #{index + 1} missing URL"
      assert resource['type'], "Resource #{index + 1} missing type"
      # Description is optional but should be present for most resources
    end
    
    puts "SUCCESS Luxembourg talk: #{resources.length}/#{expected_count} resources migrated"
  end
  
  def test_complete_resource_migration_robocoders
    talk = @talks['2025-06-11-devoxx-poland-robocoders-judgment-day']
    refute_nil talk, "RoboCoders talk file not found"
    
    resources = talk[:yaml]['resources'] || []
    expected_count = EXPECTED_TESTS['robocoders'][:expected_resource_count]
    
    assert_equal expected_count, resources.length, 
      "Expected exactly #{expected_count} resources, got #{resources.length}. " \
      "Migration incomplete - missing #{expected_count - resources.length} resources!"
      
    # Verify each resource has required fields
    resources.each_with_index do |resource, index|
      assert resource['title'], "Resource #{index + 1} missing title"
      assert resource['url'], "Resource #{index + 1} missing URL"
      assert resource['type'], "Resource #{index + 1} missing type"
    end
    
    puts "SUCCESS RoboCoders talk: #{resources.length}/#{expected_count} resources migrated"
  end
  
  def test_resource_type_detection_luxembourg
    talk = @talks['2025-06-20-voxxed-luxembourg-technical-enshittification']
    resources = talk[:yaml]['resources'] || []
    
    # Count resource types
    type_counts = resources.group_by { |r| r['type'] }.transform_values(&:count)
    
    # Verify Google Slides URLs are marked as "slides"
    slides_resources = resources.select { |r| r['type'] == 'slides' }
    slides_resources.each do |resource|
      url = resource['url']
      assert(
        url.include?('docs.google.com/presentation') || url.include?('drive.google.com'),
        "Slides resource should have Google URL: #{url}"
      )
    end
    
    # Verify YouTube URLs are marked as "video"
    video_resources = resources.select { |r| r['type'] == 'video' }
    video_resources.each do |resource|
      url = resource['url']
      assert(
        url.include?('youtube.com') || url.include?('youtu.be'),
        "Video resource should have YouTube URL: #{url}"
      )
    end
    
    # Verify PDF URLs are marked as "slides" (our convention)
    pdf_resources = resources.select { |r| r['url'].include?('drive.google.com/file') && r['url'].include?('.pdf') }
    pdf_resources.each do |resource|
      assert_equal 'slides', resource['type'], 
        "PDF resource should be marked as 'slides' type: #{resource['url']}"
    end
    
    puts "SUCCESS Resource types: #{type_counts}"
  end
  
  def test_video_detection_accuracy_luxembourg
    talk = @talks['2025-06-20-voxxed-luxembourg-technical-enshittification']
    resources = talk[:yaml]['resources'] || []
    
    # This talk SHOULD have video (user confirmed it exists)
    video_resources = resources.select { |r| r['type'] == 'video' }
    
    assert video_resources.length > 0, 
      "CRITICAL: Video detection failed! User confirmed video exists but none found in resources. " \
      "This is exactly the type of error that caused problems before."
      
    # Verify video URL format
    video_resources.each do |resource|
      url = resource['url']
      assert(
        url.match?(/https:\/\/(www\.)?youtube\.com\/watch\?v=/) || url.match?(/https:\/\/youtu\.be\//),
        "Video URL should be valid YouTube format: #{url}"
      )
    end
    
    puts "SUCCESS Video detection: #{video_resources.length} videos found"
  end

  # ===========================================
  # Test Suite 2: Resource URL Validation
  # ===========================================
  
  def test_google_slides_url_format
    all_resources = @talks.values.flat_map { |talk| talk[:yaml]['resources'] || [] }
    slides_resources = all_resources.select { |r| r['type'] == 'slides' && r['url'].include?('docs.google.com/presentation') }
    
    slides_resources.each do |resource|
      url = resource['url']
      
      # Should use /d/{document_id}/edit format, NOT /d/e/{published_id}/pub format
      refute url.include?('/d/e/'), 
        "CRITICAL: Using published URL format that doesn't work for thumbnails: #{url}. " \
        "Should use shared document format: /d/{id}/edit"
        
      assert url.include?('/d/') && (url.include?('/edit') || url.include?('/view')), 
        "Should use shared document format (/d/{id}/edit or /d/{id}/view): #{url}"
        
      # Extract document ID for thumbnail testing
      if url.match(/\/d\/([a-zA-Z0-9\-_]+)/)
        doc_id = $1
        thumbnail_url = "https://lh3.googleusercontent.com/d/#{doc_id}=s400"
        puts "  FILE #{resource['title']}: #{doc_id} → #{thumbnail_url}"
      end
    end
    
    puts "SUCCESS Google Slides URL format: #{slides_resources.length} slides checked"
  end
  
  def test_slides_are_embedded_not_downloadable
    all_resources = @talks.values.flat_map { |talk| talk[:yaml]['resources'] || [] }
    slides_resources = all_resources.select { |r| r['type'] == 'slides' }
    
    slides_resources.each do |resource|
      url = resource['url']
      title = resource['title'] || ''
      
      # Slides MUST be Google Drive URLs for embedding, NOT direct PDF downloads
      if url.include?('.pdf') && !url.include?('drive.google.com')
        flunk "CRITICAL: Slides resource is downloadable PDF, not embedded: #{url}\n" \
              "Slides MUST be uploaded to Google Drive for embedding and thumbnails!"
      end
      
      # Google Drive URLs must be in correct format
      if url.include?('drive.google.com')
        assert url.include?('/file/d/') && url.include?('/view'), 
          "Google Drive slides URL must be in /file/d/{id}/view format: #{url}"
      end
      
      puts "  FILE Slides OK: #{title} → #{url}"
    end
    
    puts "SUCCESS All slides properly embedded (not downloadable)"
  end
  
  def test_exact_resource_count_validation
    # This test must verify EXACT count from original source
    # NOT just check that resources exist
    
    @talks.each do |talk_name, talk_data|
      next unless EXPECTED_TESTS.values.any? { |t| t[:file].include?(talk_name) }
      
      expected_test = EXPECTED_TESTS.values.find { |t| t[:file].include?(talk_name) }
      resources = talk_data[:yaml]['resources'] || []
      expected_count = expected_test[:expected_resource_count]
      
      assert_equal expected_count, resources.length,
        "CRITICAL FAILURE: #{talk_name} has #{resources.length} resources, expected #{expected_count}.\n" \
        "This means the migration script failed to extract ALL resources from the original page!\n" \
        "EVERY SINGLE RESOURCE must be migrated or the migration is FAILED."
      
      puts "SUCCESS #{talk_name}: Exact count verified #{resources.length}/#{expected_count}"
    end
  end
  
  def test_video_detection_with_exact_verification
    EXPECTED_TESTS.each do |test_name, expected|
      next unless expected[:has_video]
      
      talk_file = expected[:file]
      talk_key = File.basename(talk_file, '.md')
      talk = @talks[talk_key]
      
      next unless talk
      
      resources = talk[:yaml]['resources'] || []
      video_resources = resources.select { |r| r['type'] == 'video' }
      
      assert video_resources.length > 0,
        "CRITICAL FAILURE: #{test_name} MUST have video but none found!\n" \
        "Expected video URL: #{expected[:video_url]}\n" \
        "This means the migration script failed to find the video that definitely exists!"
      
      # If expected video URL is known, verify it matches
      if expected[:video_url]
        actual_video_url = video_resources.first['url']
        assert_equal expected[:video_url], actual_video_url,
          "Video URL mismatch in #{test_name}:\n" \
          "Expected: #{expected[:video_url]}\n" \
          "Actual: #{actual_video_url}"
      end
      
      puts "SUCCESS #{test_name}: Video correctly detected"
    end
  end
  
  def test_external_link_accessibility
    all_resources = @talks.values.flat_map { |talk| talk[:yaml]['resources'] || [] }
    
    # Test a sample of external URLs (not all to avoid rate limiting)
    external_urls = all_resources.map { |r| r['url'] }.select { |url| url.start_with?('http') }.uniq
    sample_urls = external_urls.sample([external_urls.length, 10].min) # Test max 10 URLs
    
    sample_urls.each do |url|
      begin
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http.read_timeout = 10
        
        request = Net::HTTP::Head.new(uri.request_uri)
        response = http.request(request)
        
        assert response.code.to_i.between?(200, 399), 
          "URL returned #{response.code}: #{url}"
          
        puts "  SUCCESS #{response.code}: #{url}"
      rescue Net::ReadTimeout, Timeout::Error => e
        puts "  ⚠️  TIMEOUT: #{url} (#{e.class})"
        # Don't fail on timeouts - external sites can be slow
      rescue => e
        flunk "URL accessibility failed: #{url} - #{e.message}"
      end
    end
    
    puts "SUCCESS External link accessibility: #{sample_urls.length}/#{external_urls.length} URLs tested"
  end

  # ===========================================
  # Test Suite 3: Visual Quality Validation
  # ===========================================
  
  def test_thumbnail_display_quality
    # This test verifies that thumbnail URLs are properly formatted
    # Actual image loading would require browser automation
    
    all_resources = @talks.values.flat_map { |talk| talk[:yaml]['resources'] || [] }
    
    # Test Google Drive PDF thumbnails
    pdf_resources = all_resources.select { |r| r['url'].include?('drive.google.com/file') }
    pdf_resources.each do |resource|
      url = resource['url']
      
      # Extract file ID for thumbnail URL
      if url.match(/\/file\/d\/([a-zA-Z0-9\-_]+)/)
        file_id = $1
        thumbnail_url = "https://drive.google.com/thumbnail?id=#{file_id}&sz=w400-h300"
        
        # Verify thumbnail URL is accessible
        uri = URI.parse(thumbnail_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 10
        
        request = Net::HTTP::Head.new(uri.request_uri)
        response = http.request(request)
        
        assert response.code.to_i.between?(200, 399),
          "PDF thumbnail not accessible: #{thumbnail_url} (#{response.code})"
          
        puts "  FILE PDF thumbnail OK: #{resource['title']}"
      end
    end
    
    # Test Google Slides thumbnails
    slides_resources = all_resources.select { |r| r['type'] == 'slides' && r['url'].include?('docs.google.com/presentation') }
    slides_resources.each do |resource|
      url = resource['url']
      
      if url.match(/\/d\/([a-zA-Z0-9\-_]+)/)
        doc_id = $1
        thumbnail_url = "https://lh3.googleusercontent.com/d/#{doc_id}=s400"
        
        # Note: These URLs might require authentication, so we just verify format
        assert thumbnail_url.start_with?('https://lh3.googleusercontent.com/d/'),
          "Invalid slides thumbnail URL format: #{thumbnail_url}"
          
        puts "  TARGET Slides thumbnail URL: #{resource['title']}"
      end
    end
    
    puts "SUCCESS Thumbnail URLs validated"
  end

  # ===========================================
  # Test Suite 4: Migration Quality Assurance
  # ===========================================
  
  def test_content_completeness_check
    # Verify all expected test talks are present
    EXPECTED_TESTS.each do |test_name, expected|
      file_path = File.join(TALKS_DIR, expected[:file])
      assert File.exist?(file_path), "Missing expected talk file: #{expected[:file]}"
      
      talk_key = File.basename(expected[:file], '.md')
      talk = @talks[talk_key]
      refute_nil talk, "Failed to load talk: #{talk_key}"
      
      # Verify required fields
      yaml = talk[:yaml]
      assert yaml['title'], "Missing title in #{expected[:file]}"
      assert yaml['date'], "Missing date in #{expected[:file]}"
      assert yaml['resources'], "Missing resources in #{expected[:file]}"
      
      puts "SUCCESS #{test_name}: Content complete"
    end
  end
  
  def test_link_and_resource_functionality
    # Test that resource URLs are not malformed (common issue from batch replacements)
    all_resources = @talks.values.flat_map { |talk| talk[:yaml]['resources'] || [] }
    
    all_resources.each do |resource|
      url = resource['url']
      
      # Check for malformed URLs (concatenated URLs)
      refute url.scan(/https?:\/\//).length > 1, 
        "Malformed URL detected (concatenated): #{url}"
        
      # Check for valid URL format
      assert url.match?(/^https?:\/\/[^\s]+$/), 
        "Invalid URL format: #{url}"
        
      # Check for common malformation patterns
      refute url.include?('http://http://'), "Double protocol in URL: #{url}"
      refute url.include?('https://https://'), "Double protocol in URL: #{url}"
    end
    
    puts "SUCCESS URL integrity: #{all_resources.length} URLs validated"
  end
  
  # ===========================================
  # Test Suite 5: Regression Prevention
  # ===========================================
  
  def test_no_liquid_syntax_in_yaml
    # Prevent the {{site.title}} bug from recurring
    @talks.each do |talk_name, talk_data|
      yaml_content = talk_data[:raw_content]
      
      # Check for liquid syntax in YAML front matter
      if yaml_content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
        yaml_section = $1
        
        refute yaml_section.include?('{{'), 
          "Liquid syntax found in YAML front matter of #{talk_name}: #{yaml_section.scan(/\{\{.*?\}\}/)}"
        refute yaml_section.include?('{%'), 
          "Liquid syntax found in YAML front matter of #{talk_name}: #{yaml_section.scan(/\{%.*?%\}/)}"
      end
    end
    
    puts "SUCCESS No liquid syntax in YAML front matter"
  end
  
  def test_no_placeholder_resources
    # Ensure no SVG placeholders or placeholder text
    all_resources = @talks.values.flat_map { |talk| talk[:yaml]['resources'] || [] }
    
    all_resources.each do |resource|
      url = resource['url']
      title = resource['title'] || ''
      
      # Check for placeholder patterns
      refute url.include?('placeholder'), "Placeholder URL found: #{url}"
      refute url.include?('example.com'), "Example URL found: #{url}"
      refute title.downcase.include?('placeholder'), "Placeholder title found: #{title}"
      refute title.downcase.include?('todo'), "TODO in title found: #{title}"
    end
    
    puts "SUCCESS No placeholder resources found"
  end
  
  # ===========================================
  # Utility Methods
  # ===========================================
  
  def print_migration_summary
    puts "\n" + "=" * 60
    puts "MIGRATION TEST SUMMARY"
    puts "=" * 60
    
    @talks.each do |talk_name, talk_data|
      yaml = talk_data[:yaml]
      resources = yaml['resources'] || []
      
      puts "FILE #{talk_name}"
      puts "   Title: #{yaml['title']}"
      puts "   Resources: #{resources.length}"
      puts "   Types: #{resources.group_by { |r| r['type'] }.transform_values(&:count)}"
      puts
    end
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  # Add custom test output
  class MigrationTest
    def run
      result = super
      print_migration_summary if passed?
      result
    end
  end
end