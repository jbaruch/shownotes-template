#!/usr/bin/env ruby

require 'yaml'

TALKS_DIR = '_talks'

def extract_source_url_from_markdown(content)
  # Look for source URL in HTML comment
  if match = content.match(/<!-- Source: (.+?) -->/)
    return match[1].strip
  end
  nil
end

talks = {}

Dir.glob("#{TALKS_DIR}/*.md").each do |file|
  content = File.read(file)
  name = File.basename(file, '.md')
  
  puts "\n=== Processing #{name} ==="
  puts "First 5 lines:"
  puts content.split("\n")[0..4].join("\n")
  
  # Handle both YAML frontmatter format and markdown-only format
  if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
    puts "DETECTED: YAML frontmatter format"
    yaml_content = YAML.safe_load($1)
    
    # Extract source URL from YAML or from HTML comment in content
    source_url = yaml_content['source_url'] || yaml_content['notist_url'] || extract_source_url_from_markdown(content)
    
    talks[name] = {
      file: file,
      yaml: yaml_content,
      raw_content: content,
      source_url: source_url
    }
    puts "Source URL from YAML/comment: #{source_url}"
  else
    puts "DETECTED: Markdown-only format"
    # Markdown-only format - extract source URL from content
    source_url = extract_source_url_from_markdown(content)
    
    if source_url
      talks[name] = {
        file: file,
        yaml: nil,
        raw_content: content,
        source_url: source_url
      }
      puts "Source URL from comment: #{source_url}"
    else
      puts "NO SOURCE URL FOUND - talk will be excluded"
    end
  end
end

puts "\n=== FINAL RESULTS ==="
puts "Total talks loaded: #{talks.length}"
talks.each do |name, data|
  puts "  #{name}: source_url = #{data[:source_url] ? 'YES' : 'NO'}"
end
