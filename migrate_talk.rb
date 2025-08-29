#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'nokogiri'
require 'yaml'
require 'json'
require 'google/apis/drive_v3'
require 'googleauth'

class TalkMigrator
  GOOGLE_DRIVE_FOLDER_ID = '1rE43G9IvgMg0S9frwA7TaEc-XEDUL8ib'
  
  def initialize(talk_url)
    @talk_url = talk_url
    @talk_data = {}
    @resources = []
    @errors = []
  end
  
  def migrate
    puts "🚀 DETERMINISTIC TALK MIGRATION"
    puts "=" * 50
    puts "URL: #{@talk_url}"
    
    # Step 1: Fetch and parse talk page
    unless fetch_talk_page
      report_failure("Failed to fetch talk page")
      return false
    end
    
    # Step 2: Extract all metadata
    unless extract_metadata
      report_failure("Failed to extract metadata")
      return false
    end
    
    # Step 3: Extract ALL resources (MUST be complete)
    unless extract_all_resources
      report_failure("Failed to extract complete resources")
      return false
    end
    
    # Step 4: Download and upload PDF if exists
    unless handle_pdf
      report_failure("Failed to handle PDF")
      return false
    end
    
    # Step 5: Find video URL if exists
    unless find_video
      report_failure("Failed to find video")
      return false
    end
    
    # Step 6: Generate Jekyll file
    unless generate_jekyll_file
      report_failure("Failed to generate Jekyll file")
      return false
    end
    
    # Step 7: Validate migration
    unless validate_migration
      report_failure("Migration validation failed")
      return false
    end
    
    puts "✅ MIGRATION SUCCESSFUL"
    puts "📄 File: #{@jekyll_file}"
    puts "🎯 Resources: #{@resources.length}"
    puts "🎬 Video: #{@talk_data[:video_url] || 'None'}"
    puts "📄 PDF: #{@talk_data[:pdf_url] || 'None'}"
    
    true
  end
  
  private
  
  def fetch_talk_page
    puts "\n1️⃣ Fetching talk page..."
    
    uri = URI.parse(@talk_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    response = http.get(uri.path)
    
    unless response.code.to_i.between?(200, 299)
      @errors << "HTTP #{response.code} when fetching #{@talk_url}"
      return false
    end
    
    begin
      @doc = Nokogiri::HTML(response.body)
      puts "✅ Page fetched successfully"
      return true
    rescue => e
      @errors << "Failed to parse HTML: #{e.message}"
      return false
    end
  end
  
  def extract_metadata
    puts "\n2️⃣ Extracting metadata..."
    
    # Title (REQUIRED)
    title_elem = @doc.css('h1').first
    unless title_elem
      @errors << "No title found (missing h1 element)"
      return false
    end
    @talk_data[:title] = title_elem.text.strip
    
    # Date and Conference (extract from page content)
    # Look for patterns like "June 11, 2025" and "Devoxx Poland 2025"
    page_text = @doc.text
    
    # Extract date (look for month day, year pattern)
    date_match = page_text.match(/(\w+\s+\d+,\s+\d{4})/)
    if date_match
      begin
        @talk_data[:date] = Date.parse(date_match[1]).strftime("%Y-%m-%d")
      rescue
        @errors << "Could not parse date: #{date_match[1]}"
        return false
      end
    else
      @errors << "No date found in page"
      return false
    end
    
    # Extract conference
    conference_patterns = [
      /Devoxx\s+\w+\s+\d{4}/,
      /Voxxed\s+Days\s+\w+\s+\d{4}/,
      /\w+\s+\d{4}/ # Fallback
    ]
    
    conference_patterns.each do |pattern|
      match = page_text.match(pattern)
      if match
        @talk_data[:conference] = match[0]
        break
      end
    end
    
    unless @talk_data[:conference]
      @errors << "No conference found in page"
      return false
    end
    
    # Extract speakers (look for author/speaker information)
    # This is a simplification - may need refinement
    @talk_data[:speaker] = extract_speakers_from_url
    
    # Extract abstract/description
    abstract_elem = @doc.css('p').find { |p| p.text.length > 100 }
    @talk_data[:abstract] = abstract_elem ? abstract_elem.text.strip : ""
    
    puts "✅ Metadata extracted:"
    puts "   Title: #{@talk_data[:title]}"
    puts "   Date: #{@talk_data[:date]}"
    puts "   Conference: #{@talk_data[:conference]}"
    puts "   Speaker: #{@talk_data[:speaker]}"
    
    true
  end
  
  def extract_all_resources
    puts "\n3️⃣ Extracting ALL resources..."
    
    # Find all links on the page that look like resources
    # Look for href attributes that point to external resources
    
    resource_links = []
    
    # Method 1: Look for a specific resources section
    resources_section = @doc.css('*:contains("Resources"), *:contains("resources")').first
    if resources_section
      resource_links.concat(resources_section.css('a[href]').map { |a| a['href'] }.compact)
    end
    
    # Method 2: Find all external links
    all_links = @doc.css('a[href]').map { |a| a['href'] }.compact
    external_links = all_links.select { |url| url.start_with?('http') }
    resource_links.concat(external_links)
    
    # Method 3: Look for specific patterns (GitHub, slides, etc.)
    resource_links.concat(all_links.select { |url| 
      url.include?('github.com') || 
      url.include?('docs.google.com') ||
      url.include?('drive.google.com') ||
      url.include?('youtube.com') ||
      url.include?('youtu.be') ||
      url.include?('slideshare.net') ||
      url.include?('.pdf')
    })
    
    # Remove duplicates and self-references
    resource_links = resource_links.uniq.reject { |url| 
      url.include?('speaking.jbaru.ch') || url.start_with?('#') || url.start_with?('/')
    }
    
    if resource_links.empty?
      @errors << "No resources found on page"
      return false
    end
    
    # Convert to resource objects with metadata
    resource_links.each_with_index do |url, index|
      resource = {
        'url' => url,
        'type' => determine_resource_type(url),
        'title' => "Resource #{index + 1}", # Will be improved
        'description' => ""
      }
      @resources << resource
    end
    
    puts "✅ Found #{@resources.length} resources"
    @resources.each_with_index do |res, i|
      puts "   #{i+1}. #{res['type']}: #{res['url']}"
    end
    
    # CRITICAL: Count verification
    expected_count = extract_resource_count_from_page
    if expected_count && expected_count != @resources.length
      @errors << "Resource count mismatch: found #{@resources.length}, expected #{expected_count}"
      return false
    end
    
    true
  end
  
  def handle_pdf
    puts "\n4️⃣ Handling PDF..."
    
    # Look for PDF links in the page or resources
    pdf_urls = find_pdf_urls
    
    if pdf_urls.empty?
      puts "⚠️  No PDF found"
      return true
    end
    
    pdf_url = pdf_urls.first
    puts "📄 Found PDF: #{pdf_url}"
    
    # Download PDF
    pdf_filename = generate_pdf_filename
    local_pdf_path = "pdfs/#{pdf_filename}"
    
    unless download_file(pdf_url, local_pdf_path)
      @errors << "Failed to download PDF from #{pdf_url}"
      return false
    end
    
    # Upload to Google Drive
    drive_url = upload_to_google_drive(local_pdf_path)
    unless drive_url
      @errors << "Failed to upload PDF to Google Drive"
      return false
    end
    
    # Add PDF as slides resource
    pdf_resource = {
      'type' => 'slides',
      'title' => extract_pdf_title,
      'url' => drive_url,
      'description' => "Complete slide deck (PDF)"
    }
    
    @resources.unshift(pdf_resource) # Add at beginning
    @talk_data[:pdf_url] = drive_url
    
    puts "✅ PDF processed and uploaded"
    true
  end
  
  def find_video
    puts "\n5️⃣ Finding video..."
    
    # Look for YouTube URLs
    youtube_patterns = [
      /https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)/,
      /https?:\/\/youtu\.be\/([a-zA-Z0-9_-]+)/
    ]
    
    page_text = @doc.to_s
    
    youtube_patterns.each do |pattern|
      match = page_text.match(pattern)
      if match
        video_url = match[0]
        @talk_data[:video_url] = video_url
        @talk_data[:status] = "completed"
        
        # Add video resource
        video_resource = {
          'type' => 'video',
          'title' => 'Full Presentation Video',
          'url' => video_url,
          'description' => 'Complete video recording'
        }
        
        # Add after slides but before other resources
        slides_index = @resources.find_index { |r| r['type'] == 'slides' }
        insert_index = slides_index ? slides_index + 1 : 0
        @resources.insert(insert_index, video_resource)
        
        puts "✅ Video found: #{video_url}"
        return true
      end
    end
    
    puts "⚠️  No video found - setting status to video-pending"
    @talk_data[:status] = "video-pending"
    true
  end
  
  def generate_jekyll_file
    puts "\n6️⃣ Generating Jekyll file..."
    
    # Generate filename
    date_part = @talk_data[:date]
    conference_slug = @talk_data[:conference].downcase.gsub(/[^a-z0-9]+/, '-')
    title_slug = @talk_data[:title].downcase.gsub(/[^a-z0-9]+/, '-')[0..50]
    @jekyll_file = "_talks/#{date_part}-#{conference_slug}-#{title_slug}.md"
    
    # Generate YAML front matter
    yaml_data = {
      'layout' => 'talk',
      'title' => @talk_data[:title],
      'speaker' => @talk_data[:speaker],
      'conference' => @talk_data[:conference],
      'date' => @talk_data[:date],
      'status' => @talk_data[:status],
      'description' => generate_description,
      'abstract' => @talk_data[:abstract],
      'resources' => @resources
    }
    
    # Generate markdown content
    content = "#{yaml_data.to_yaml}---\n\n"
    content += generate_markdown_body
    
    # Write file
    File.write(@jekyll_file, content)
    puts "✅ Jekyll file generated: #{@jekyll_file}"
    
    true
  end
  
  def validate_migration
    puts "\n7️⃣ Validating migration..."
    
    # Check file exists and is readable
    unless File.exist?(@jekyll_file)
      @errors << "Generated Jekyll file does not exist"
      return false
    end
    
    # Parse and validate YAML
    begin
      content = File.read(@jekyll_file)
      yaml_match = content.match(/\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m)
      unless yaml_match
        @errors << "Invalid YAML front matter"
        return false
      end
      
      parsed_yaml = YAML.safe_load(yaml_match[1])
      
      # Validate required fields
      required_fields = %w[title speaker conference date status resources]
      required_fields.each do |field|
        unless parsed_yaml[field]
          @errors << "Missing required field: #{field}"
          return false
        end
      end
      
      # Validate resources
      resources = parsed_yaml['resources']
      unless resources.is_a?(Array) && !resources.empty?
        @errors << "Resources must be a non-empty array"
        return false
      end
      
      resources.each_with_index do |resource, i|
        %w[type title url].each do |req_field|
          unless resource[req_field]
            @errors << "Resource #{i+1} missing #{req_field}"
            return false
          end
        end
      end
      
      puts "✅ Migration validation passed"
      puts "   Resources: #{resources.length}"
      puts "   Required fields: ✓"
      puts "   YAML structure: ✓"
      
      true
    rescue => e
      @errors << "Validation error: #{e.message}"
      return false
    end
  end
  
  def report_failure(message)
    puts "❌ MIGRATION FAILED: #{message}"
    puts "\n🔍 ERRORS:"
    @errors.each_with_index do |error, i|
      puts "   #{i+1}. #{error}"
    end
    puts "\nFIX THESE ISSUES AND TRY AGAIN"
  end
  
  # Helper methods
  
  def determine_resource_type(url)
    case url
    when /github\.com/
      'code'
    when /docs\.google\.com\/presentation/
      'slides'  
    when /drive\.google\.com.*\.pdf/
      'slides'
    when /youtube\.com|youtu\.be/
      'video'
    else
      'link'
    end
  end
  
  def extract_speakers_from_url
    # Extract speaker info from URL pattern
    if @talk_url.include?('speaking.jbaru.ch')
      'Baruch Sadogursky'
    else
      'Unknown Speaker'
    end
  end
  
  def extract_resource_count_from_page
    # Look for "X Resources" text pattern
    match = @doc.text.match(/(\d+)\s+Resources?/i)
    match ? match[1].to_i : nil
  end
  
  def find_pdf_urls
    pdf_urls = []
    
    # Look for direct PDF links
    @doc.css('a[href$=".pdf"]').each do |link|
      pdf_urls << link['href']
    end
    
    # Look for notist cloud PDF pattern
    page_text = @doc.to_s
    notist_match = page_text.match(/https?:\/\/on\.notist\.cloud\/pdf\/[^"'\s]+\.pdf/)
    pdf_urls << notist_match[0] if notist_match
    
    pdf_urls.uniq
  end
  
  def generate_pdf_filename
    date_part = @talk_data[:date]
    conference_slug = @talk_data[:conference].downcase.gsub(/[^a-z0-9]+/, '-')
    title_slug = @talk_data[:title].downcase.gsub(/[^a-z0-9]+/, '-')[0..30]
    "#{date_part}-#{conference_slug}-#{title_slug}.pdf"
  end
  
  def download_file(url, local_path)
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(local_path))
    
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    response = http.get(uri.path)
    
    if response.code.to_i.between?(200, 299)
      File.open(local_path, 'wb') { |file| file.write(response.body) }
      true
    else
      false
    end
  end
  
  def upload_to_google_drive(local_path)
    # Note: This may fail due to service account limitations
    # Return nil if it fails, handle gracefully
    begin
      service = Google::Apis::DriveV3::DriveService.new
      service.client_options.application_name = 'Shownotes Migration'
      
      service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open('Google API.json'),
        scope: ['https://www.googleapis.com/auth/drive']
      )
      
      file_metadata = Google::Apis::DriveV3::File.new(
        name: File.basename(local_path),
        parents: [GOOGLE_DRIVE_FOLDER_ID]
      )
      
      uploaded_file = service.create_file(file_metadata, upload_source: local_path)
      
      # Make public
      permission = Google::Apis::DriveV3::Permission.new(role: 'reader', type: 'anyone')
      service.create_permission(uploaded_file.id, permission)
      
      "https://drive.google.com/file/d/#{uploaded_file.id}/view"
    rescue => e
      puts "⚠️  Google Drive upload failed: #{e.message}"
      nil
    end
  end
  
  def extract_pdf_title
    "#{@talk_data[:title]} - Slides"
  end
  
  def generate_description
    "Presentation from #{@talk_data[:conference]}"
  end
  
  def generate_markdown_body
    # Generate basic markdown content
    content = "# #{@talk_data[:title]}\n\n"
    content += "#{@talk_data[:abstract]}\n\n" if @talk_data[:abstract] && !@talk_data[:abstract].empty?
    content += "## Resources\n\nThis talk includes #{@resources.length} resources covering the topics discussed.\n"
    content
  end
end

# CLI usage
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: #{$0} <talk_url>"
    puts "Example: #{$0} https://speaking.jbaru.ch/PjlHKD/robocoders-judgment-day-ai-ides-face-off"
    exit 1
  end
  
  migrator = TalkMigrator.new(ARGV[0])
  success = migrator.migrate
  exit success ? 0 : 1
end