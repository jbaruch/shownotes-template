#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'nokogiri'

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
  puts "Found resources section: #{resources_section ? 'YES' : 'NO'}"
  
  if resources_section
    # Get links that are actual content resources
    links = resources_section.css('a[href]')
    puts "Found #{links.length} links in resources section"
    
    links.each_with_index do |link, i|
      href = link['href']
      title = link.text.strip
      
      puts "Link #{i+1}: '#{title}' -> #{href}"
      
      # Skip navigation/metadata links
      next if href.include?('notist.st') || href.include?('noti.st')
      next if href.include?('twitter.com/intent') 
      next if href.start_with?('#') || href.start_with?('/')
      next if title.empty? || title.length < 3
      
      resource_links << {
        url: href,
        title: title
      }
      puts "  -> INCLUDED"
    end
  end
  
  puts "Total resources extracted: #{resource_links.length}"
  resource_links
end

# Test the extraction
url = "https://speaking.jbaru.ch/V8R94I/technical-enshittification-why-everything-in-it-is-horrible-right-now-and-how-to-fix-it"
resources = extract_resources_from_source(url)
puts "\nFinal count: #{resources.length}"
