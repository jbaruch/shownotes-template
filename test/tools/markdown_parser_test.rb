#!/usr/bin/env ruby

# Add the current directory to the load path
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'jekyll'
require_relative '../../_plugins/markdown_parser'

# Sample content from our markdown file
content = <<~MARKDOWN
# Voxxed Luxembourg Technical Enshittification

**Conference:** Voxxed Days Luxembourg 2025
**Date:** 2025-06-20  
**Slides:** [View Slides](https://drive.google.com/file/d/1vAOI6cYus5abZHM2zepIQgBBPCN8qLUl/view)
**Video:** [Watch Video](https://youtube.com/watch?v=iFN1Y_8Cuik)

This talk explores the concept of technical enshittification - how technology platforms and tools degrade over time, becoming less useful for their original purpose while extracting more value from users.

## Resources

- [Original essay on enshittification](https://example.com/essay)
- [Platform economics research](https://example.com/research)
MARKDOWN

# Create a test class that includes our module methods
class TestParser
  def extract_title_from_content(content)
    return nil unless content
    
    match = content.to_s.match(/^# (.+)$/m)
    match ? match[1].strip : nil
  end
  
  def extract_metadata_from_content(content, field)
    return nil unless content
    
    pattern = /^\*\*#{Regexp.escape(field.capitalize)}:\*\*\s*(.+)$/i
    match = content.to_s.match(pattern)
    match ? match[1].strip : nil
  end
  
  def extract_description_from_content(content)
    return nil unless content
    
    # Extract the main paragraph content between metadata and resources
    lines = content.to_s.split("\n")
    start_idx = lines.find_index { |line| line.match?(/^\*\*.*\*\*/) }
    end_idx = lines.find_index { |line| line.strip.start_with?('## Resources') }
    
    if start_idx && end_idx
      desc_lines = lines[(start_idx + 1)...end_idx]
      desc_lines.join("\n").strip
    elsif start_idx
      desc_lines = lines[(start_idx + 1)..-1] || []
      desc_lines.join("\n").strip
    else
      content.to_s.strip
    end
  end
  
  def extract_resources_from_content(content)
    return '' unless content
    
    lines = content.to_s.split("\n")
    resources_start = lines.find_index { |line| line.strip.start_with?('## Resources') }
    return '' unless resources_start
    
    resource_lines = lines[(resources_start + 1)..-1] || []
    resource_lines.join("\n").strip
  end
end

parser = TestParser.new

puts "Testing markdown parsing:"
puts "Title: '#{parser.extract_title_from_content(content)}'"
puts "Conference: '#{parser.extract_metadata_from_content(content, 'conference')}'"
puts "Date: '#{parser.extract_metadata_from_content(content, 'date')}'"
puts "Slides: '#{parser.extract_metadata_from_content(content, 'slides')}'"
puts "Video: '#{parser.extract_metadata_from_content(content, 'video')}'"
puts "Description: '#{parser.extract_description_from_content(content)}'"
puts "Resources: '#{parser.extract_resources_from_content(content)}'"
