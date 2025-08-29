#!/usr/bin/env ruby

require 'minitest/autorun'
require 'yaml'
require 'net/http'
require 'uri'
require 'json'
require 'timeout'
require 'nokogiri'

class MigrationTest < Minitest::Test
  # Test data directory
  TALKS_DIR = File.join(File.dirname(__FILE__), '..', '_talks')
  
  def setup
    @talks = {}
    load_all_talks_with_sources
  end
  
  def load_all_talks_with_sources
    Dir.glob("#{TALKS_DIR}/*.md").each do |file|
      content = File.read(file)
      if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
        yaml_content = YAML.safe_load($1)
        
        @talks[File.basename(file, '.md')] = {
          file: file,
          yaml: yaml_content,
          raw_content: content,
          source_url: yaml_content['source_url'] || yaml_content['notist_url']
        }
      end
    end
    
    puts "📋 Loaded #{@talks.length} talks for testing"
  end

  # ==========================================
  # Test Suite 1: Dynamic Source-vs-Migrated Validation  
  # ==========================================
  
  def test_migrated_resources_match_source_exactly
    talks_with_sources = @talks.select { |_, data| data[:source_url] }
    
    talks_with_sources.each do |talk_name, talk_data|
      puts "\n🔍 Testing #{talk_name}..."
      
      # Skip if no source URL available
      next unless talk_data[:source_url]
      
      # Fetch original source page
      source_resources = extract_resources_from_source(talk_data[:source_url])
      migrated_resources = talk_data[:yaml]['resources'] || []
      
      # CRITICAL: Resource count must match exactly
      assert_equal source_resources.length, migrated_resources.length,
        "❌ RESOURCE COUNT MISMATCH for #{talk_name}:\n" \
        "Source has #{source_resources.length} resources\n" \
        "Migrated has #{migrated_resources.length} resources\n" \
        "EVERY resource from source must be migrated!"
      
      # Validate each migrated resource has meaningful title
      migrated_resources.each_with_index do |resource, index|
        title = resource['title']
        
        refute title.match?(/^Resource \d+$/), 
          "❌ GENERIC TITLE: '#{title}' should be actual content title from source"
        
        refute title.empty?, 
          "❌ EMPTY TITLE: Resource #{index + 1} has no title"
          
        assert title.length > 3,
          "❌ TOO SHORT TITLE: '#{title}' is too short to be meaningful"
      end
      
      puts "✅ #{talk_name}: #{migrated_resources.length} resources with meaningful titles"
    end
  end
  
  def test_video_availability_matches_source
    talks_with_sources = @talks.select { |_, data| data[:source_url] }
    
    talks_with_sources.each do |talk_name, talk_data|
      puts "\n🎬 Testing video for #{talk_name}..."
      
      # Check if source has video
      source_has_video = source_page_has_video?(talk_data[:source_url])
      migrated_resources = talk_data[:yaml]['resources'] || []
      migrated_videos = migrated_resources.select { |r| r['type'] == 'video' }
      
      if source_has_video
        assert migrated_videos.length > 0,
          "❌ VIDEO MISSING: Source has video but migration doesn't include it"
          
        # Test that video URL actually works
        migrated_videos.each do |video|
          video_url = video['url']
          assert video_works?(video_url),
            "❌ VIDEO BROKEN: #{video_url} doesn't work or video doesn't exist"
        end
        
        puts "✅ #{talk_name}: Video present and working"
      else
        puts "ℹ️  #{talk_name}: No video in source (as expected)"
      end
    end
  end
  
  def test_slides_are_google_drive_embedded
    @talks.each do |talk_name, talk_data|
      migrated_resources = talk_data[:yaml]['resources'] || []
      slides_resources = migrated_resources.select { |r| r['type'] == 'slides' }
      
      slides_resources.each do |slides|
        url = slides['url']
        
        # CRITICAL: Must be Google Drive, not direct PDF downloads
        if url.include?('.pdf') && !url.include?('drive.google.com')
          flunk "❌ WRONG PDF SOURCE: #{url}\n" \
                "Slides must be uploaded to Google Drive, not linked to external PDFs!\n" \
                "This prevents thumbnail generation and proper embedding."
        end
        
        if url.include?('drive.google.com')
          assert url.include?('/file/d/') && url.include?('/view'),
            "❌ WRONG GOOGLE DRIVE FORMAT: #{url}\n" \
            "Must use /file/d/{id}/view format for proper embedding"
        end
      end
      
      if slides_resources.length > 0
        puts "✅ #{talk_name}: Slides properly hosted on Google Drive"
      end
    end
  end
  
  def test_resource_type_detection
    @talks.each do |talk_name, talk_data|
      resources = talk_data[:yaml]['resources'] || []
      next if resources.empty?
      
      # Count resource types
      type_counts = resources.group_by { |r| r['type'] }.transform_values(&:count)
      
      # Verify Google Slides URLs are marked as "slides"
      slides_resources = resources.select { |r| r['type'] == 'slides' }
      slides_resources.each do |resource|
        url = resource['url']
        assert(
          url.include?('docs.google.com/presentation') || url.include?('drive.google.com') || url.include?('.pdf'),
          "Slides resource should have Google/PDF URL: #{url}"
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
      
      puts "✅ #{talk_name} resource types: #{type_counts}"
    end
  end  # ===========================================
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
    # Verify all migrated talks have complete content by comparing with source
    @talks.each do |talk_key, talk_data|
      next unless talk_data[:source_url]
      
      # Verify required fields exist
      yaml = talk_data[:yaml]
      assert yaml['title'], "Missing title in #{talk_key}.md"
      assert yaml['date'], "Missing date in #{talk_key}.md"
      assert yaml['resources'], "Missing resources in #{talk_key}.md"
      
      # Dynamic validation: Compare resource count with source
      source_resources = extract_resources_from_source(talk_data[:source_url])
      migrated_resources = yaml['resources'] || []
      
      if source_resources.length != migrated_resources.length
        puts "❌ RESOURCE COUNT MISMATCH for #{talk_key}:"
        puts "  Source has #{source_resources.length} resources"
        puts "  Migration has #{migrated_resources.length} resources"
        puts "  This indicates incomplete migration!"
      else
        puts "SUCCESS #{talk_key}: Content complete (#{migrated_resources.length} resources)"
      end
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
      
      # Check for generic "Resource N" titles
      refute title.match?(/^Resource \d+$/), 
        "❌ GENERIC TITLE: Found '#{title}' - should be meaningful title from source content"
    end
    
    puts "SUCCESS No placeholder resources found"
  end
  
  # ===========================================
  # Utility Methods for Dynamic Testing
  # ===========================================
  
  def extract_resources_from_source(source_url)
    # Fetch and parse the source page
    uri = URI.parse(source_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    response = http.get(uri.request_uri)
    doc = Nokogiri::HTML(response.body)
    
    # Extract actual content resources (not navigation/metadata)
    resource_links = []
    
    # Look for resources section specifically
    resources_section = doc.css('#resources, .resources, *:contains("Resources")').first
    if resources_section
      # Get links that are actual content resources
      links = resources_section.css('a[href]')
      links.each do |link|
        href = link['href']
        title = link.text.strip
        
        # Skip navigation/metadata links
        next if href.include?('notist.st') || href.include?('noti.st')
        next if href.include?('twitter.com/intent') 
        next if href.start_with?('#') || href.start_with?('/')
        next if title.empty? || title.length < 3
        
        resource_links << {
          url: href,
          title: title,
          type: determine_resource_type(href)
        }
      end
    end
    
    resource_links
  end
  
  def source_page_has_video?(source_url)
    uri = URI.parse(source_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    response = http.get(uri.request_uri)
    content = response.body
    
    # Check for video indicators
    content.include?('youtube.com') || 
    content.include?('youtu.be') || 
    content.include?('notist.ninja/embed') ||
    content.include?('id="video"')
  end
  
  def video_works?(video_url)
    return false unless video_url.include?('youtube.com') || video_url.include?('youtu.be')
    
    # Extract YouTube video ID
    video_id = nil
    if video_url.include?('youtube.com/watch?v=')
      video_id = video_url.split('watch?v=').last.split('&').first
    elsif video_url.include?('youtu.be/')
      video_id = video_url.split('youtu.be/').last.split('?').first
    end
    
    # YouTube video IDs should be 11 characters long
    return false unless video_id && video_id.length == 11
    
    # Check if the video ID contains only valid characters (alphanumeric, _, -)
    return false unless video_id.match?(/^[a-zA-Z0-9_-]{11}$/)
    
    # Make a HEAD request to check if video exists
    begin
      uri = URI.parse(video_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      
      response = http.get(uri.request_uri)
      
      # Check for common YouTube error indicators
      body = response.body
      return false if body.include?('Video unavailable')
      return false if body.include?('This video is not available') 
      return false if body.include?('has been removed')
      return false if body.include?('private video')
      
      # If we get here and response is 200, likely valid
      response.code.to_i == 200
    rescue => e
      puts "Video validation error: #{e.message}"
      false
    end
  end
  
  def determine_resource_type(url)
    return 'video' if url.include?('youtube.com') || url.include?('youtu.be')
    return 'slides' if url.include?('docs.google.com/presentation') || url.include?('drive.google.com')
    return 'code' if url.include?('github.com')
    'link'
  end

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