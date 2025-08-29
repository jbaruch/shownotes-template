module Jekyll
  class MarkdownTalkProcessor < Generator
    safe true
    priority :high

    def generate(site)
      site.collections['talks'].docs.each do |doc|
        content = doc.content
        
        # Extract metadata from markdown content
        doc.data['extracted_title'] = extract_title_from_content(content)
        doc.data['extracted_conference'] = extract_metadata_from_content(content, 'conference')
        doc.data['extracted_date'] = extract_metadata_from_content(content, 'date')
        doc.data['extracted_slides'] = extract_metadata_from_content(content, 'slides')
        doc.data['extracted_video'] = extract_metadata_from_content(content, 'video')
        doc.data['extracted_description'] = extract_description_from_content(content)
        doc.data['extracted_resources'] = extract_resources_from_content(content)
      end
    end

    private

    def extract_title_from_content(content)
      return 'Untitled Talk' unless content
      
      lines = content.to_s.split("\n")
      first_line = lines.find { |line| line.strip.start_with?('# ') }
      if first_line
        title = first_line.strip[2..-1].strip
        return title.empty? ? 'Untitled Talk' : title
      end
      'Untitled Talk'
    end
    
    def extract_metadata_from_content(content, field)
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
    
    def extract_description_from_content(content)
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
    
    def extract_resources_from_content(content)
      return '' unless content
      
      lines = content.to_s.split("\n")
      resources_start = lines.find_index { |line| line.strip.start_with?('## Resources') }
      return '' unless resources_start
      
      resource_lines = lines[(resources_start + 1)..-1] || []
      resource_lines.join("\n").strip
    end
  end
end
