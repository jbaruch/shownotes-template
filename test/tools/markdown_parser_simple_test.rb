#!/usr/bin/env ruby

module MarkdownParser
  def self.extract_title_from_content(content)
    return 'Untitled Talk' unless content
    
    lines = content.to_s.split("\n")
    first_line = lines.find { |line| line.strip.start_with?('# ') }
    if first_line
      title = first_line.strip[2..-1].strip
      return title.empty? ? 'Untitled Talk' : title
    end
    'Untitled Talk'
  end
  
  def self.extract_metadata_from_content(content, field)
    return nil unless content
    
    pattern = /^\*\*#{Regexp.escape(field.capitalize)}:\*\*\s*(.+)$/i
    match = content.to_s.match(pattern)
    return nil unless match
    
    value = match[1].strip
    # Extract URL from markdown link if present
    if value.match(/\[([^\]]+)\]\(([^)]+)\)/)
      return $2  # Return the URL
    else
      return value
    end
  end
  
  def self.extract_description_from_content(content)
    return '' unless content
    
    lines = content.to_s.split("\n")
    
    # Find content after the title and metadata but before Resources
    description_lines = []
    in_description = false
    
    lines.each do |line|
      stripped = line.strip
      
      # Skip title line
      next if stripped.start_with?('# ')
      
      # Skip metadata lines
      next if stripped.match(/^\*\*\w+:\*\*/)
      
      # Start collecting after empty line following metadata
      if stripped.empty? && !in_description
        in_description = true
        next
      end
      
      # Stop at Resources section
      break if stripped.start_with?('## Resources')
      
      # Collect description content
      if in_description && !stripped.empty?
        description_lines << stripped
      elsif in_description && stripped.empty? && !description_lines.empty?
        break  # End of first paragraph
      end
    end
    
    description_lines.join(' ')
  end
  
  def self.extract_resources_from_content(content)
    return '' unless content
    
    lines = content.to_s.split("\n")
    resources_start = lines.find_index { |line| line.strip.start_with?('## Resources') }
    return '' unless resources_start
    
    resource_lines = lines[(resources_start + 1)..-1] || []
    resource_lines.join("\n").strip
  end
end

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

puts "Testing markdown parsing:"
puts "Title: '#{MarkdownParser.extract_title_from_content(content)}'"
puts "Conference: '#{MarkdownParser.extract_metadata_from_content(content, 'conference')}'"
puts "Date: '#{MarkdownParser.extract_metadata_from_content(content, 'date')}'"
puts "Slides: '#{MarkdownParser.extract_metadata_from_content(content, 'slides')}'"
puts "Video: '#{MarkdownParser.extract_metadata_from_content(content, 'video')}'"
puts "Description: '#{MarkdownParser.extract_description_from_content(content)}'"
puts "Resources: '#{MarkdownParser.extract_resources_from_content(content)}'"
