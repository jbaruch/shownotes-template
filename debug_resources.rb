#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'nokogiri'
require 'set'

def determine_resource_type(url)
  return 'video' if url.include?('youtube.com') || url.include?('youtu.be')
  return 'slides' if url.include?('docs.google.com/presentation') || url.include?('drive.google.com') || url.include?('.pdf')
  'resource'
end

def extract_resources_from_source(source_url)
  return [] if source_url.nil? || source_url.empty?

  puts "🔍 Fetching source URL: #{source_url}"
  
  uri = URI.parse(source_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true if uri.scheme == 'https'
  
  response = http.get(uri.request_uri)
  
  if response.code != '200'
    puts "❌ Failed to fetch source page: #{response.code}"
    return []
  end
  
  doc = Nokogiri::HTML(response.body)
  
  # Extract actual content resources (not navigation/metadata)
  resource_links = []
  
  # Look for resources section specifically
  resources_section = doc.css('#resources')
  if resources_section.any?
    puts "✅ Found resources section"
    # Use the same precise selector as migration script
    links = resources_section.css('.resource-list li h3 a')
    puts "🔗 Found #{links.length} resource links"
    
    links.each_with_index do |link, index|
      href = link['href']
      title = link.text.strip
      
      puts "  #{index + 1}. Title: '#{title}' URL: '#{href}'"
      
      # Skip only invalid/malformed links (same logic as migration script)
      if href.start_with?('#') || href.start_with?('/')
        puts "    ⚠️  Skipping: relative URL"
        next
      end
      
      if title.empty? || title.length < 3
        puts "    ⚠️  Skipping: title too short or empty"
        next
      end
      
      if href.nil? || href.empty?
        puts "    ⚠️  Skipping: empty URL"
        next
      end
      
      # Skip URLs with leading/trailing whitespace (migration script filters these out)
      if href != href.strip
        puts "    ⚠️  Skipping: URL has whitespace"
        next
      end
      
      resource_type = determine_resource_type(href)
      
      # EXCLUDE slides and video resources from count comparison
      # These are handled separately in migration and don't appear in ## Resources section
      if resource_type == 'slides' || resource_type == 'video'
        puts "    ⚠️  Skipping: #{resource_type} (handled separately)"
        next
      end
      
      puts "    ✅ Including: #{resource_type}"
      
      resource_links << {
        url: href,
        title: title,
        type: resource_type
      }
    end
  else
    puts "❌ No resources section found"
  end
  
  # Deduplicate resources by URL (same logic as migration script)
  unique_resources = []
  seen_urls = Set.new
  
  resource_links.each do |resource|
    url = resource[:url]
    unless seen_urls.include?(url)
      seen_urls.add(url)
      unique_resources << resource
    else
      puts "    🔄 Duplicate URL skipped: #{url}"
    end
  end
  
  puts "📊 Final source resource count: #{unique_resources.length}"
  unique_resources
end

def extract_migrated_resources(content)
  resources = []
  
  puts "🔍 Extracting migrated resources..."
  
  # Find the Resources section
  lines = content.split("\n")
  resources_start = -1
  
  lines.each_with_index do |line, index|
    if line.strip == "## Resources"
      resources_start = index
      puts "✅ Found Resources section at line #{index + 1}"
      break
    end
  end
  
  if resources_start == -1
    puts "❌ No Resources section found in migrated content"
    return resources
  end
  
  # Extract resource lines after the ## Resources header
  resource_count = 0
  (resources_start + 1...lines.length).each do |i|
    line = lines[i].strip
    
    # Stop if we hit another section header
    if line.start_with?("## ")
      puts "🛑 Stopped at next section: #{line}"
      break
    end
    
    # Parse lines that start with "- ["
    if match = line.match(/^- \[(.+?)\]\((.+?)\)/)
      resource_count += 1
      title = match[1]
      url = match[2]
      
      puts "  #{resource_count}. Title: '#{title}' URL: '#{url}'"
      
      # Only skip if URL is invalid - allow empty titles to be caught by validation
      if url.nil? || url.empty?
        puts "    ⚠️  Skipping: empty URL"
        next
      end
      
      resource_type = determine_resource_type(url)
      puts "    ✅ Including: #{resource_type}"
      
      resources << {
        'title' => title,
        'url' => url,
        'type' => resource_type
      }
    end
  end
  
  puts "📊 Final migrated resource count: #{resources.length}"
  resources
end

# Test the specific talk
source_url = "https://speaking.jbaru.ch/YGW5XP/developer-productivity-diy-with-chatgpt-or-how-i-learned-to-stop-worrying-and-love-the-ai"
content = File.read("/Users/jbaruch/Projects/shownotes/_talks/2023-09-18-infobip-shift-developer-productivity.md")

puts "=" * 80
puts "SOURCE RESOURCES"
puts "=" * 80
source_resources = extract_resources_from_source(source_url)

puts "\n" + "=" * 80
puts "MIGRATED RESOURCES"
puts "=" * 80
migrated_resources = extract_migrated_resources(content)

puts "\n" + "=" * 80
puts "COMPARISON"
puts "=" * 80
puts "Source resources: #{source_resources.length}"
puts "Migrated resources: #{migrated_resources.length}"
puts "Difference: #{migrated_resources.length - source_resources.length}"

if source_resources.length != migrated_resources.length
  puts "\n🔍 DETAILED COMPARISON:"
  
  puts "\nSource resources:"
  source_resources.each_with_index do |resource, index|
    puts "  #{index + 1}. #{resource[:title]} (#{resource[:url]})"
  end
  
  puts "\nMigrated resources:"
  migrated_resources.each_with_index do |resource, index|
    puts "  #{index + 1}. #{resource['title']} (#{resource['url']})"
  end
  
  # Find what's in migrated but not in source
  source_urls = source_resources.map { |r| r[:url] }.to_set
  migrated_urls = migrated_resources.map { |r| r['url'] }.to_set
  
  extra_in_migrated = migrated_urls - source_urls
  missing_in_migrated = source_urls - migrated_urls
  
  if extra_in_migrated.any?
    puts "\n➕ Extra resources in migrated (not in source):"
    extra_in_migrated.each { |url| puts "  - #{url}" }
  end
  
  if missing_in_migrated.any?
    puts "\n➖ Missing resources in migrated (present in source):"
    missing_in_migrated.each { |url| puts "  - #{url}" }
  end
end
