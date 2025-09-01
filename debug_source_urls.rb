#!/usr/bin/env ruby

Dir.glob('_talks/*.md').each do |file|
  content = File.read(file)
  name = File.basename(file, '.md')
  
  # Check for source URL in HTML comment
  if match = content.match(/<!-- Source: (.+?) -->/)
    source_url = match[1].strip
    puts "#{name}: HAS source URL - #{source_url}"
  else
    puts "#{name}: NO source URL found"
  end
end
