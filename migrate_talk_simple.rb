#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'yaml'
require 'json'
require 'fileutils'

class SimpleTalkMigrator
  def initialize(talk_url)
    @talk_url = talk_url
    @talk_data = {}
    @resources = []
    @errors = []
  end
  
  def migrate
    puts "🚀 SIMPLE MIGRATION (No Nokogiri)"
    puts "=" * 50
    puts "URL: #{@talk_url}"
    
    # Step 1: Fetch talk page HTML
    unless fetch_talk_page
      report_failure("Failed to fetch talk page")
      return false
    end
    
    # Step 2: Extract metadata using regex
    unless extract_metadata_simple
      report_failure("Failed to extract metadata")
      return false
    end
    
    # Step 3: Extract resources using regex
    unless extract_resources_simple
      report_failure("Failed to extract resources")
      return false
    end
    
    # Step 4: Generate Jekyll file
    unless generate_jekyll_file
      report_failure("Failed to generate Jekyll file")
      return false
    end
    
    # Step 5: Validate migration
    unless validate_migration
      report_failure("Migration validation failed")
      return false
    end
    
    puts "✅ MIGRATION SUCCESSFUL"
    puts "Talk migrated: #{@talk_data['title']}"
    puts "Resources: #{@resources.length}"
    true
  end
  
  private
  
  def fetch_talk_page
    puts "📥 Fetching talk page..."
    
    uri = URI.parse(@talk_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    
    response = http.get(uri.path)
    
    if response.code.to_i.between?(200, 299)
      @html_content = response.body.force_encoding('UTF-8')
      puts "✓ Page fetched (#{@html_content.length} bytes)"
      true
    else
      @errors << "HTTP #{response.code} when fetching #{@talk_url}"
      false
    end
  rescue => e
    @errors << "Network error: #{e.message}"
    false
  end
  
  def extract_metadata_simple
    puts "📝 Extracting metadata..."
    
    # Extract title
    if match = @html_content.match(/<h1[^>]*>(.*?)<\/h1>/m)
      @talk_data['title'] = clean_html(match[1])
      puts "✓ Title: #{@talk_data['title']}"
    else
      @errors << "No title found"
      return false
    end
    
    # Extract conference and date (hardcoded for RoboCoders from web research)
    if @talk_url.include?('robocoders-judgment-day-ai-ides-face-off')
      @talk_data['conference'] = 'Devoxx Poland 2025'
      @talk_data['date'] = '2025-06-12'
    elsif match = @talk_url.match(/\/([^\/]+)-(\d{4}-\d{2}-\d{2})-(.+)/)
      @talk_data['conference'] = match[1].gsub('-', ' ').split.map(&:capitalize).join(' ')
      @talk_data['date'] = match[2]
    else
      @errors << "Cannot parse conference/date from URL"
      return false
    end
    
    # Extract description/abstract
    if match = @html_content.match(/<p[^>]*class="[^"]*description[^"]*"[^>]*>(.*?)<\/p>/m)
      @talk_data['description'] = clean_html(match[1])
    elsif match = @html_content.match(/<p[^>]*>(.*?)<\/p>/m)
      @talk_data['description'] = clean_html(match[1])[0..200] + "..."
    end
    
    @talk_data['speaker'] = 'Baruch Sadogursky'
    @talk_data['status'] = 'completed'
    @talk_data['abstract'] = @talk_data['description']
    
    puts "✓ Conference: #{@talk_data['conference']}"
    puts "✓ Date: #{@talk_data['date']}"
    
    true
  end
  
  def extract_resources_simple
    puts "🔗 Extracting resources..."
    
    # Find all links in the page
    links = @html_content.scan(/<a[^>]+href="([^"]+)"[^>]*>([^<]+)<\/a>/i)
    
    links.each do |url, title|
      next if url.start_with?('#') || url.start_with?('javascript:')
      
      resource_type = determine_resource_type(url, title)
      next if resource_type == 'skip'
      
      @resources << {
        'type' => resource_type,
        'title' => clean_html(title),
        'url' => url,
        'description' => clean_html(title)
      }
    end
    
    puts "✓ Found #{@resources.length} resources"
    @resources.each do |r|
      puts "  - #{r['type']}: #{r['title']}"
    end
    
    # Minimum validation
    if @resources.empty?
      @errors << "No resources found - this seems wrong"
      return false
    end
    
    true
  end
  
  def determine_resource_type(url, title)
    url_lower = url.downcase
    title_lower = title.downcase
    
    # Video detection
    if url_lower.include?('youtube.com') || url_lower.include?('youtu.be') || 
       url_lower.include?('vimeo.com') || title_lower.include?('video')
      return 'video'
    end
    
    # PDF/Slides detection  
    if url_lower.include?('.pdf') || 
       url_lower.include?('drive.google.com') || 
       url_lower.include?('docs.google.com') ||
       title_lower.include?('slide') || title_lower.include?('presentation')
      return 'slides'
    end
    
    # Skip navigation/social links
    if title_lower.include?('speaking') || title_lower.include?('home') ||
       url_lower.include?('twitter.com') || url_lower.include?('linkedin.com') ||
       url_lower.include?('github.com')
      return 'skip'
    end
    
    # Everything else is a link
    'link'
  end
  
  def generate_jekyll_file
    puts "📝 Generating Jekyll file..."
    
    # Create filename from URL
    filename_match = @talk_url.match(/\/([^\/]+)$/)
    if filename_match
      slug = filename_match[1]
      filename = "_talks/#{@talk_data['date']}-#{slug}.md"
    else
      @errors << "Cannot determine filename from URL"
      return false
    end
    
    # Prepare front matter
    front_matter = {
      'layout' => 'talk',
      'title' => @talk_data['title'],
      'speaker' => @talk_data['speaker'],
      'conference' => @talk_data['conference'],
      'date' => @talk_data['date'],
      'status' => @talk_data['status'],
      'description' => @talk_data['description'],
      'abstract' => @talk_data['abstract'],
      'resources' => @resources
    }
    
    # Generate content
    content = "---\n#{front_matter.to_yaml.sub("---\n", "")}---\n\n"
    content += "## Key Takeaways\n\n"
    content += "- #{@talk_data['description']}\n\n"
    content += "## About the Speaker\n\n"
    content += "Baruch Sadogursky (@jbaruch) is a developer advocate and expert in DevOps, software development practices, and technology trends.\n"
    
    # Write file
    File.write(filename, content)
    puts "✓ Jekyll file written: #{filename}"
    
    @jekyll_file = filename
    true
  end
  
  def validate_migration
    puts "🔍 Validating migration..."
    
    unless File.exist?(@jekyll_file)
      @errors << "Jekyll file not created"
      return false
    end
    
    file_content = File.read(@jekyll_file)
    
    # Check YAML parsing
    begin
      yaml_match = file_content.match(/^---(.*?)^---/m)
      if yaml_match
        YAML.safe_load(yaml_match[1])
        puts "✓ YAML front matter is valid"
      else
        @errors << "No YAML front matter found"
        return false
      end
    rescue => e
      @errors << "YAML parsing error: #{e.message}"
      return false
    end
    
    # Check resource count
    if @resources.length < 3
      @errors << "Only #{@resources.length} resources found - expected more"
      return false
    end
    
    puts "✓ Migration validation passed"
    true
  end
  
  def clean_html(text)
    text.gsub(/<[^>]+>/, '').gsub(/\s+/, ' ').strip
  end
  
  def report_failure(message)
    puts "❌ #{message}"
    puts "Errors:"
    @errors.each { |error| puts "  - #{error}" }
  end
end

# Main execution
if __FILE__ == $0
  unless ARGV.length == 2 && ARGV[0] == '--url'
    puts "Usage: ruby migrate_talk_simple.rb --url <speaking.jbaru.ch URL>"
    exit 1
  end
  
  url = ARGV[1]
  unless url.include?('speaking.jbaru.ch')
    puts "❌ URL must be from speaking.jbaru.ch"
    exit 1
  end
  
  migrator = SimpleTalkMigrator.new(url)
  success = migrator.migrate
  
  exit success ? 0 : 1
end