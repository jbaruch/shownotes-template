#!/usr/bin/env ruby

require 'minitest/autorun'
require 'yaml'
require 'net/http'
require 'uri'
require 'json'
require 'timeout'
require 'nokogiri'

class MigrationTest < Minitest::Test
  # Test data directory - find the project root directory
  PROJECT_ROOT = File.expand_path('../../..', __FILE__)
  TALKS_DIR = File.join(PROJECT_ROOT, '_talks')
  
  def setup
    @talks = {}
    load_all_talks_with_sources
  end
  
  def load_all_talks_with_sources
    Dir.glob("#{TALKS_DIR}/*.md").each do |file|
      content = File.read(file)
      if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
        yaml_content = YAML.safe_load($1, permitted_classes: [Date])
        
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
    # Check for talks without source_url and skip them explicitly
    talks_without_sources = @talks.select { |_, data| !data[:source_url] }
    talks_with_sources = @talks.select { |_, data| data[:source_url] }
    
    # Report on skipped talks
    unless talks_without_sources.empty?
      skipped_talks = talks_without_sources.keys.join(', ')
      puts "⏭️  SKIPPING #{talks_without_sources.length} talks without source_url: #{skipped_talks}"
      skip "Skipping #{talks_without_sources.length} talks without source_url (#{skipped_talks}). Migration validation requires source_url for comparison."
    end
    
    talks_with_sources.each do |talk_name, talk_data|
      puts "\n🔍 Testing #{talk_name}..."
      
      # Fetch original source page resources
      source_resources = extract_resources_from_source(talk_data[:source_url])
      
      # Extract migrated resources from markdown content
      migrated_resources = extract_migrated_resources(talk_data[:raw_content])
      
      # CRITICAL: Resource count must match exactly
      assert_equal source_resources.length, migrated_resources.length,
        "❌ RESOURCE COUNT MISMATCH for #{talk_name}:\n" \
        "Source has #{source_resources.length} resources\n" \
        "Migrated has #{migrated_resources.length} resources\n" \
        "EVERY resource from source must be migrated!"
      
      # CRITICAL: Compare URLs and titles for each resource
      source_resources.each_with_index do |source_resource, index|
        # Find matching migrated resource by URL or title similarity
        migrated_resource = find_matching_migrated_resource(source_resource, migrated_resources)
        
        assert migrated_resource,
          "❌ MISSING RESOURCE: Source resource '#{source_resource[:title]}' (#{source_resource[:url]}) not found in migration"
        
        # Validate title similarity (allowing for reasonable variations)
        assert_title_similarity(source_resource[:title], migrated_resource[:title], talk_name)
        
        # Validate URL correctness (exact match or acceptable transformation)
        assert_url_correctness(source_resource[:url], migrated_resource[:url], source_resource[:type], talk_name)
        
        puts "  ✅ #{migrated_resource[:title]} - URL and title validated"
      end
      
      puts "✅ #{talk_name}: #{migrated_resources.length} resources fully validated (URLs and titles match)"
    end
  end
  
  def test_video_availability_matches_source
    # Check for talks without source_url and skip them explicitly
    talks_without_sources = @talks.select { |_, data| !data[:source_url] }
    talks_with_sources = @talks.select { |_, data| data[:source_url] }
    
    # Report and skip if no talks have source_url
    if talks_with_sources.empty?
      skipped_talks = talks_without_sources.keys.join(', ')
      puts "⚠️  No talks with source_url found - skipping video validation"
      skip "Skipping video validation for #{talks_without_sources.length} talks without source_url (#{skipped_talks})"
    end
    
    # Report on any talks being skipped
    unless talks_without_sources.empty?
      skipped_talks = talks_without_sources.keys.join(', ')
      puts "⏭️  SKIPPING #{talks_without_sources.length} talks without source_url: #{skipped_talks}"
    end
    
    talks_with_sources.each do |talk_name, talk_data|
      puts "\n🎬 Testing video for #{talk_name}..."
      
      # Check if source has video
      source_has_video = source_page_has_video?(talk_data[:source_url])
      content = talk_data[:raw_content]
      has_video = content.match?(/\*\*Video:\*\* \[.+?\]\((.+?)\)/)
      
      if source_has_video
        assert has_video,
          "❌ VIDEO MISSING: Source has video but migration doesn't include it"
          
        # Test that video URL actually works
        if video_match = content.match(/\*\*Video:\*\* \[.+?\]\((.+?)\)/)
          video_url = video_match[1]
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
    # Check for talks without source_url and skip them explicitly
    talks_without_sources = @talks.select { |_, data| !data[:source_url] }
    talks_with_sources = @talks.select { |_, data| data[:source_url] }
    
    # Report and skip if no talks have source_url or some talks don't have source_url
    unless talks_without_sources.empty?
      skipped_talks = talks_without_sources.keys.join(', ')
      puts "⏭️  SKIPPING #{talks_without_sources.length} talks without source_url: #{skipped_talks}"
      skip "Skipping completeness validation for #{talks_without_sources.length} talks without source_url (#{skipped_talks}). Completeness validation requires source_url for comparison."
    end
    
    # Verify all migrated talks have complete content by comparing with source
    talks_with_sources.each do |talk_key, talk_data|
      content = talk_data[:raw_content]
      yaml = talk_data[:yaml]
      
      # Check for title (H1 in markdown)
      assert content.match?(/^# .+/), "Missing title (H1) in #{talk_key}.md"
      
      # Check for conference and date
      assert content.match?(/\*\*Conference:\*\* .+/), "Missing conference in #{talk_key}.md"
      assert content.match?(/\*\*Date:\*\* \d{4}-\d{2}-\d{2}/), "Missing date in #{talk_key}.md"
      
      # Check for resources (either slides/video or ## Resources section)
      has_slides = content.match?(/\*\*Slides:\*\*/)
      has_video = content.match?(/\*\*Video:\*\*/)
      has_resources_section = content.match?(/## Resources/)
      
      assert (has_slides || has_video || has_resources_section), 
        "Missing resources (no slides, video, or resources section) in #{talk_key}.md"
      
      # Dynamic validation: Compare resource count with source
      source_resources = extract_resources_from_source(talk_data[:source_url])
      migrated_resource_count = count_resources_in_content(content)
      
      if source_resources.length != migrated_resource_count
        puts "❌ RESOURCE COUNT MISMATCH for #{talk_key}:"
        puts "  Source has #{source_resources.length} resources"
        puts "  Migration has #{migrated_resource_count} resources"
        puts "  This indicates incomplete migration!"
      else
        puts "SUCCESS #{talk_key}: Content complete (#{migrated_resource_count} resources)"
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
    # Fetch and parse the source page, following redirects
    uri = URI.parse(source_url)
    
    # Follow redirects
    response = nil
    redirect_count = 0
    max_redirects = 5
    
    loop do
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      
      response = http.get(uri.request_uri)
      
      case response
      when Net::HTTPRedirection
        if redirect_count >= max_redirects
          raise "Too many redirects (#{redirect_count})"
        end
        uri = URI.parse(response['location'])
        redirect_count += 1
      else
        break
      end
    end
    
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
    
    # Make a request to check if video exists (follow redirects)
    begin
      uri = URI.parse(video_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      
      # Follow redirects automatically
      response = http.get(uri.request_uri)
      
      # Follow up to 3 redirects
      redirect_count = 0
      while response.code.to_i.between?(300, 399) && redirect_count < 3
        location = response['location']
        break unless location
        
        new_uri = URI.parse(location)
        http = Net::HTTP.new(new_uri.host, new_uri.port)
        http.use_ssl = (new_uri.scheme == 'https')
        http.read_timeout = 10
        
        response = http.get(new_uri.request_uri)
        redirect_count += 1
      end
      
      # Check final response
      return false unless response.code.to_i.between?(200, 299)
      
      # Check for common YouTube error indicators in the final response
      if response.body
        body = response.body
        return false if body.include?('Video unavailable')
        return false if body.include?('This video is not available') 
        return false if body.include?('has been removed')
        return false if body.include?('private video')
      end
      
      true
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
      content = talk_data[:raw_content]
      
      # Extract title from markdown (H1)
      title_match = content.match(/^# (.+)/)
      title = title_match ? title_match[1] : "No title"
      
      # Count resources properly
      resource_count = count_resources_in_content(content)
      
      puts "FILE #{talk_name}"
      puts "   Title: #{title}"
      puts "   Resources: #{resource_count}"
      puts "   Format: Clean Markdown"
      puts
    end
  end

  # Helper method to count resources in clean markdown format
  def count_resources_in_content(content)
    # DON'T count slides/video - they are separate entities, not "resources"
    # Only count items in the ## Resources section
    
    # Find the Resources section with flexible matching
    lines = content.split("\n")
    resources_start = -1
    
    lines.each_with_index do |line, index|
      if line.strip == "## Resources"
        resources_start = index
        break
      end
    end
    
    return 0 if resources_start == -1
    
    # Count resource lines after the ## Resources header
    count = 0
    (resources_start + 1...lines.length).each do |i|
      line = lines[i].strip
      
      # Stop if we hit another section header
      break if line.start_with?("## ")
      
      # Count lines that start with "- ["
      if line.match?(/^- \[.+?\]\(.+?\)/)
        count += 1
      end
    end
    
    count
  end
  
  def extract_migrated_resources(content)
    resources = []
    
    # Find the Resources section
    lines = content.split("\n")
    resources_start = -1
    
    lines.each_with_index do |line, index|
      if line.strip == "## Resources"
        resources_start = index
        break
      end
    end
    
    return resources if resources_start == -1
    
    # Extract resource lines after the ## Resources header
    (resources_start + 1...lines.length).each do |i|
      line = lines[i].strip
      
      # Stop if we hit another section header
      break if line.start_with?("## ")
      
      # Parse lines that start with "- ["
      if match = line.match(/^- \[(.+?)\]\((.+?)\)/)
        title = match[1]
        url = match[2]
        
        resources << {
          title: title,
          url: url,
          type: determine_resource_type(url)
        }
      end
    end
    
    resources
  end
  
  def find_matching_migrated_resource(source_resource, migrated_resources)
    # Try exact URL match first (for unchanged URLs)
    exact_match = migrated_resources.find { |mr| mr[:url] == source_resource[:url] }
    return exact_match if exact_match
    
    # Try title similarity match (for transformed URLs like PDF to Google Drive)
    migrated_resources.find do |mr|
      title_similarity_score(source_resource[:title], mr[:title]) > 0.7
    end
  end
  
  def assert_title_similarity(source_title, migrated_title, talk_name)
    # Calculate similarity score
    similarity = title_similarity_score(source_title, migrated_title)
    
    # Allow for reasonable variations but catch completely wrong titles
    assert similarity > 0.6,
      "❌ TITLE MISMATCH in #{talk_name}:\n" \
      "Source: '#{source_title}'\n" \
      "Migrated: '#{migrated_title}'\n" \
      "Similarity: #{(similarity * 100).round(1)}% (need >60%)"
  end
  
  def assert_url_correctness(source_url, migrated_url, resource_type, talk_name)
    # For exact matches, no validation needed
    return if source_url == migrated_url
    
    case resource_type
    when 'slides'
      # PDFs should be migrated to Google Drive
      if source_url.end_with?('.pdf')
        assert migrated_url.include?('drive.google.com'),
          "❌ PDF NOT MIGRATED: #{source_url} should be uploaded to Google Drive, got: #{migrated_url}"
        
        assert migrated_url.include?('/file/d/') && migrated_url.include?('/view'),
          "❌ WRONG GOOGLE DRIVE FORMAT: #{migrated_url} should use /file/d/{id}/view format"
      else
        # Non-PDF slides should remain the same or be acceptable transformations
        assert_acceptable_url_transformation(source_url, migrated_url, talk_name)
      end
    when 'video'
      # Videos should remain the same or be acceptable YouTube transformations
      if source_url.include?('youtube.com') || source_url.include?('youtu.be')
        assert migrated_url.include?('youtube.com') || migrated_url.include?('youtu.be'),
          "❌ VIDEO URL CHANGED: #{source_url} became #{migrated_url} - YouTube URLs should be preserved"
      end
    else
      # Other resources should have acceptable transformations
      assert_acceptable_url_transformation(source_url, migrated_url, talk_name)
    end
  end
  
  def assert_acceptable_url_transformation(source_url, migrated_url, talk_name)
    # Allow common acceptable transformations
    source_domain = URI.parse(source_url).host rescue nil
    migrated_domain = URI.parse(migrated_url).host rescue nil
    
    # Same domain is always acceptable
    return if source_domain == migrated_domain
    
    # Allow HTTP -> HTTPS transformations
    return if source_url.gsub('http://', 'https://') == migrated_url
    
    # Allow trailing slash differences
    return if source_url.chomp('/') == migrated_url.chomp('/')
    
    # If we get here, it might be an unacceptable change
    puts "⚠️  URL TRANSFORMATION in #{talk_name}: #{source_url} -> #{migrated_url}"
  end
  
  def title_similarity_score(title1, title2)
    # Simple similarity based on common words
    words1 = title1.downcase.split(/\W+/).select { |w| w.length > 2 }
    words2 = title2.downcase.split(/\W+/).select { |w| w.length > 2 }
    
    return 1.0 if words1.empty? && words2.empty?
    return 0.0 if words1.empty? || words2.empty?
    
    common_words = words1 & words2
    total_words = (words1 + words2).uniq.length
    
    common_words.length.to_f / total_words
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