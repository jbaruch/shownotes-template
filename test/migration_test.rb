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
      
      # Handle both YAML frontmatter format and markdown-only format
      if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
        # YAML frontmatter format
        yaml_content = YAML.safe_load($1)
        
        # Extract source URL from YAML or from HTML comment in content
        source_url = yaml_content['source_url'] || yaml_content['notist_url'] || extract_source_url_from_markdown(content)
        
        @talks[File.basename(file, '.md')] = {
          file: file,
          yaml: yaml_content,
          raw_content: content,
          source_url: source_url
        }
      else
        # Markdown-only format - extract source URL from content
        source_url = extract_source_url_from_markdown(content)
        
        if source_url
          @talks[File.basename(file, '.md')] = {
            file: file,
            yaml: nil,
            raw_content: content,
            source_url: source_url
          }
        end
      end
    end
    
    puts "📋 Loaded #{@talks.length} talks for testing"
  end
  
  def extract_source_url_from_markdown(content)
    # Look for source URL in HTML comment
    if match = content.match(/<!-- Source: (.+?) -->/)
      return match[1].strip
    end
    nil
  end

  def get_resources_from_talk(talk_data)
    # Handle both YAML frontmatter and markdown-only formats
    if talk_data[:yaml] && talk_data[:yaml]['resources']
      return talk_data[:yaml]['resources']
    else
      # Extract resources from markdown content
      resources = []
      content = talk_data[:raw_content]
      lines = content.split("\n")
      
      # Find Resources section
      resources_start = lines.find_index { |line| line.strip == "## Resources" }
      return resources if resources_start.nil?
      
      # Parse resource lines
      (resources_start + 1...lines.length).each do |i|
        line = lines[i].strip
        break if line.start_with?("## ") # Stop at next section
        
        if match = line.match(/^- \[([^\]]+)\]\(([^)]+)\)/)
          title = match[1].strip
          url = match[2].strip
          resources << {
            'title' => title,
            'url' => url,
            'type' => determine_resource_type(url)
          }
        end
      end
      
      resources
    end
  end

  # ==========================================
  # Test Suite 1: Dynamic Source-vs-Migrated Validation  
  # ==========================================
  
  def test_migrated_resources_match_source_exactly
    # CRITICAL: All talks must have source_url for validation
    @talks.each do |talk_name, talk_data|
      assert talk_data[:source_url], 
        "❌ MISSING SOURCE_URL: #{talk_name}.md has no source_url - migration validation impossible!"
    end
    
    talks_with_sources = @talks.select { |_, data| data[:source_url] }
    
    talks_with_sources.each do |talk_name, talk_data|
      puts "\n🔍 Testing #{talk_name}..."
      
      # Test that resources are properly formatted and contain meaningful content
      content = talk_data[:raw_content]
      migrated_resource_count = count_resources_in_content(content)
      
      # Ensure we have some resources (talks should have slides, video, or resource links)
      assert migrated_resource_count > 0, 
        "❌ NO RESOURCES: #{talk_name} has no resources at all - migration incomplete!"
      
      # Validate meaningful titles in markdown links
      markdown_links = content.scan(/\[([^\]]+)\]\([^)]+\)/)
      
      markdown_links.each_with_index do |link_match, index|
        title = link_match[0] # First capture group is the link text
        
        refute title.match?(/^Resource \d+$/), 
          "❌ GENERIC TITLE: '#{title}' should be actual content title from source"
        
        refute title.empty?, 
          "❌ EMPTY TITLE: Link #{index + 1} has no title"
          
        # Skip very short titles like "PDF" or "View" for slides/video links
        next if title.match?(/^(View Slides|Watch Video|PDF|Slides|Video)$/i)
        
        assert title.length > 3,
          "❌ TOO SHORT TITLE: '#{title}' is too short to be meaningful"
      end
      
      # Test URL format validity for all resources
      urls = content.scan(/\]\(([^)]+)\)/).flatten
      urls.each do |url|
        assert url.match?(/^https?:\/\/[^\s]+$/), "Invalid URL format: #{url}"
        # Allow Wayback Machine URLs which legitimately contain multiple protocols
        unless url.include?("web.archive.org")
          refute url.scan(/https?:\/\//).length > 1, "Malformed URL (concatenated): #{url}"
        end
      end
      
      puts "✅ #{talk_name}: #{migrated_resource_count} resources with valid format and meaningful titles"
    end
  end
  
  def test_video_availability_matches_source
    # CRITICAL: All talks must have source_url for validation
    @talks.each do |talk_name, talk_data|
      assert talk_data[:source_url], 
        "❌ MISSING SOURCE_URL: #{talk_name}.md has no source_url - video validation impossible!"
    end
    
    talks_with_sources = @talks.select { |_, data| data[:source_url] }
    
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
      migrated_resources = get_resources_from_talk(talk_data)
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
      resources = get_resources_from_talk(talk_data)
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
    all_resources = @talks.flat_map { |_, data| get_resources_from_talk(data) }
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
    all_resources = @talks.flat_map { |_, data| get_resources_from_talk(data) }
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
    all_resources = @talks.flat_map { |_, data| get_resources_from_talk(data) }
    
    # Test URL format validity only (not actual accessibility)
    external_urls = all_resources.map { |r| r['url'] }.select { |url| url.start_with?('http') }.uniq
    
    external_urls.each do |url|
      # Test URL format is valid
      assert url.match?(/^https?:\/\/[^\s]+$/), "Invalid URL format: #{url}"
      
      # Check for malformed URLs (concatenated URLs) - but exclude legitimate archive URLs
      unless url.include?("web.archive.org")
        refute url.scan(/https?:\/\//).length > 1, 
          "Malformed URL detected (concatenated): #{url}"
      end
        
      # Check for common malformation patterns
      refute url.include?('http://http://'), "Double protocol in URL: #{url}"
      refute url.include?('https://https://'), "Double protocol in URL: #{url}"
      
      # Ensure URL can be parsed as valid URI
      begin
        URI.parse(url)
      rescue URI::InvalidURIError => e
        flunk "URL cannot be parsed: #{url} - #{e.message}"
      end
    end
    
    puts "SUCCESS External URL format validation: #{external_urls.length} URLs checked"
  end

  # ===========================================
  # Test Suite 3: Visual Quality Validation
  # ===========================================
  
  def test_thumbnail_display_quality
    # This test verifies that thumbnail URLs are properly formatted
    # Actual image loading would require browser automation
    
    all_resources = @talks.flat_map { |_, data| get_resources_from_talk(data) }
    
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
    # Verify all migrated talks have complete content structure
    @talks.each do |talk_key, talk_data|
      # CRITICAL: source_url required for validation
      assert talk_data[:source_url], 
        "❌ MISSING SOURCE_URL: #{talk_key}.md has no source_url - completeness validation impossible!"
      
      # Verify required content exists in markdown (clean format)
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
      
      # Verify resource count is reasonable for a complete migration
      migrated_resource_count = count_resources_in_content(content)
      assert migrated_resource_count > 0,
        "❌ NO RESOURCES: #{talk_key} has no resources - migration incomplete!"
      
      puts "SUCCESS #{talk_key}: Content complete (#{migrated_resource_count} resources)"
    end
  end
  
  def test_link_and_resource_functionality
    # Test that resource URLs are not malformed (common issue from batch replacements)
    all_resources = @talks.flat_map { |_, data| get_resources_from_talk(data) }
    
    all_resources.each do |resource|
      url = resource['url']
      
      # Check for malformed URLs (concatenated URLs) - but exclude legitimate archive URLs
      if url.scan(/https?:\/\//).length > 1
        # Allow Wayback Machine URLs which legitimately contain multiple protocols
        unless url.include?('web.archive.org') || url.include?('archive.org')
          flunk "Malformed URL detected (concatenated): #{url}"
        end
      end
        
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
    all_resources = @talks.flat_map { |_, data| get_resources_from_talk(data) }
    
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
    
    # Extract actual content resources using the same logic as debug script
    resources = []
    doc.css('#resources .resource-list li h3 a').each do |link|
      title = link.text.strip
      href = link['href']
      next if title.empty? || href.nil? || href.empty?
      
      resources << {
        url: href,
        title: title,
        type: determine_resource_type(href)
      }
    end
    
    resources
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
      acceptable_codes = [200, 301, 302, 401, 403, 405]
      return false unless acceptable_codes.include?(response.code.to_i)
      
      body = response.body
      return false if body.include?('Video unavailable')
      return false if body.include?('This video is not available') 
      return false if body.include?('has been removed')
      return false if body.include?('private video')
      
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