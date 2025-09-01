require 'nokogiri'
require 'net/http'
require 'uri'

url = 'https://speaking.jbaru.ch/V8R94I/technical-enshittification-why-everything-in-it-is-horrible-right-now-and-how-to-fix-it'
uri = URI.parse(url)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
response = http.get(uri.path)
doc = Nokogiri::HTML(response.body)

# Test what the migration test is doing
resources_section = doc.css('#resources')
puts "Resources section found: #{resources_section.any?}"

if resources_section.any?
  links = resources_section.css('.resource-list li h3 a')
  puts "Links in resources section: #{links.length}"
  
  valid_links = []
  links.each do |link|
    href = link['href']
    title = link.text.strip
    
    # Skip only invalid/malformed links
    next if href.start_with?('#') || href.start_with?('/')
    next if title.empty? || title.length < 3
    next if href.nil? || href.empty?
    
    valid_links << { url: href, title: title }
  end
  
  puts "Valid resource links: #{valid_links.length}"
  puts "First 5:"
  valid_links.first(5).each_with_index do |link, i|
    puts "#{i+1}. #{link[:title]} -> #{link[:url]}"
  end
end

# Check for video more thoroughly
content = response.body
puts "\nVideo detection:"
puts "Contains youtube.com: #{content.include?('youtube.com')}"
puts "Contains youtu.be: #{content.include?('youtu.be')}"
puts "Contains notist.ninja/embed: #{content.include?('notist.ninja/embed')}"
puts "Contains id=\"video\": #{content.include?('id="video"')}"

# Look for actual YouTube URLs
youtube_matches = content.scan(/https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)/)
youtu_be_matches = content.scan(/https?:\/\/youtu\.be\/([a-zA-Z0-9_-]+)/)

puts "YouTube URLs found: #{youtube_matches.length}"
puts "Youtu.be URLs found: #{youtu_be_matches.length}"
