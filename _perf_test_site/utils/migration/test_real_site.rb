#!/usr/bin/env ruby

require 'net/http'
require 'uri'

def fetch_site_content(url)
  uri = URI(url)
  response = Net::HTTP.get_response(uri)
  
  unless response.code == '200'
    puts "Failed to fetch #{url}: HTTP #{response.code}"
    exit 1
  end
  
  response.body
rescue => e
  puts "Failed to fetch #{url}: #{e.message}"
  exit 1
end

# Test the real site
site_url = 'http://127.0.0.1:4000'
content = fetch_site_content(site_url)

puts "Testing real site at #{site_url}..."

# Test social media links
social_checks = [
  ['social-link linkedin', 'LinkedIn link'],
  ['social-link x', 'X/Twitter link'], 
  ['social-link github', 'GitHub link'],
  ['social-link bluesky', 'Bluesky link'],
  ['speaker-social-links', 'Social links container']
]

puts "\nSocial Media Tests:"
social_checks.each do |pattern, description|
  if content.include?(pattern)
    puts "✅ #{description} - FOUND"
  else
    puts "❌ #{description} - MISSING"
  end
end

# Test avatar
avatar_checks = [
  ['github.com/', 'GitHub avatar URL'],
  ['.png?size=200', 'Avatar size parameter'],
  ['class="author-avatar"', 'Avatar CSS class']
]

puts "\nAvatar Tests:"
avatar_checks.each do |pattern, description|
  if content.include?(pattern)
    puts "✅ #{description} - FOUND"
  else
    puts "❌ #{description} - MISSING"
  end
end

# Test basic structure
structure_checks = [
  ['class="hero-section"', 'Hero section'],
  ['class="hero-content"', 'Hero content'],
  ['id="main-content"', 'Main content area'],
  ['Presentations by', 'Title text']
]

puts "\nStructure Tests:"
structure_checks.each do |pattern, description|
  if content.include?(pattern)
    puts "✅ #{description} - FOUND"
  else
    puts "❌ #{description} - MISSING"
  end
end

puts "\n✨ Real site integration test completed!"
