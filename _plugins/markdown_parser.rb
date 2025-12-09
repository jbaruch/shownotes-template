module Jekyll
  # Hook to process markdown-only files by adding frontmatter during site initialization
  Jekyll::Hooks.register :site, :after_init do |site|
    # Process talks collection files that lack frontmatter
    talks_dir = File.join(site.source, '_talks')
    if Dir.exist?(talks_dir)
      Dir.glob(File.join(talks_dir, '*.md')).each do |file_path|
        content = File.read(file_path)
        
        # Check if file lacks YAML frontmatter
        if !content.start_with?('---')
          # Add minimal frontmatter
          new_content = "---\nlayout: talk\n---\n\n#{content}"
          File.write(file_path, new_content)
        end
      end
    end
  end

  class MarkdownTalkProcessor < Generator
    safe true
    priority :highest

    def generate(site)
      Jekyll.logger.info "MarkdownTalkProcessor:", "Starting plugin execution in #{Jekyll.env} environment"
      
      talks_collection = site.collections['talks']
      if talks_collection && talks_collection.docs
        Jekyll.logger.info "MarkdownTalkProcessor:", "Found #{talks_collection.docs.size} talks to process"
        
        talks_collection.docs.each do |doc|
          begin
            Jekyll.logger.debug "MarkdownTalkProcessor:", "Processing #{doc.path}"
            content = doc.content
            
            # Extract metadata from markdown content
            doc.data['extracted_title'] = extract_title_from_content(content)
            doc.data['extracted_conference'] = extract_metadata_from_content(content, 'conference')
            doc.data['extracted_date'] = extract_metadata_from_content(content, 'date')
            doc.data['extracted_slides'] = extract_metadata_from_content(content, 'slides')
            doc.data['extracted_video'] = extract_metadata_from_content(content, 'video')
            # Only extract description from content if not already in front matter
            if !doc.data['extracted_description'] || doc.data['extracted_description'].empty?
              doc.data['extracted_description'] = extract_description_from_content(content)
            end
            # Extract abstract from content if not in front matter
            if !doc.data['extracted_abstract'] || doc.data['extracted_abstract'].empty?
              doc.data['extracted_abstract'] = extract_abstract_from_content(content)
            end
            doc.data['extracted_resources'] = extract_resources_from_content(content)
            doc.data['extracted_presentation_context'] = extract_and_process_presentation_context(content, site)
            
            Jekyll.logger.debug "MarkdownTalkProcessor:", "Extracted title: #{doc.data['extracted_title']}"
            Jekyll.logger.debug "MarkdownTalkProcessor:", "Extracted conference: #{doc.data['extracted_conference']}"
          rescue => e
            Jekyll.logger.error "MarkdownTalkProcessor:", "Failed to process #{doc.path}: #{e.message}"
            Jekyll.logger.error "MarkdownTalkProcessor:", e.backtrace.join("\n")
            
            # Set fallback values to prevent template errors
            doc.data['extracted_title'] ||= doc.data['title'] || 'Untitled Talk'
            doc.data['extracted_conference'] ||= 'Unknown Conference'
            doc.data['extracted_date'] ||= ''
            doc.data['extracted_slides'] ||= ''
            doc.data['extracted_video'] ||= ''
            doc.data['extracted_description'] ||= ''
            doc.data['extracted_abstract'] ||= ''
            doc.data['extracted_resources'] ||= ''
            doc.data['extracted_presentation_context'] ||= ''
          end
        end
        
        Jekyll.logger.info "MarkdownTalkProcessor:", "Successfully processed #{talks_collection.docs.size} talks"
      else
        Jekyll.logger.warn "MarkdownTalkProcessor:", "No talks collection found or collection is empty"
      end

      # Add convenience method for accessing talks collection
      unless site.respond_to?(:talks)
        site.define_singleton_method(:talks) do
          talks_collection = collections['talks']
          talks_collection ? talks_collection.docs : []
        end
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
      
      # First try to extract from ## Abstract section
      abstract_content = extract_from_abstract_section(content)
      return abstract_content unless abstract_content.empty?
      
      # Fall back to legacy extraction method
      extract_description_legacy(content)
    end
    
    def extract_abstract_from_content(content)
      return '' unless content
      
      # First try to extract from ## Abstract section
      abstract_content = extract_from_abstract_section(content)
      return abstract_content unless abstract_content.empty?
      
      # Fall back to legacy extraction method
      extract_abstract_legacy(content)
    end
    
    def extract_from_abstract_section(content)
      return '' unless content
      
      lines = content.to_s.split("\n")
      abstract_lines = []
      in_abstract_section = false
      
      lines.each do |line|
        stripped = line.strip
        
        # Start collecting when we find ## Abstract
        if stripped == '## Abstract'
          in_abstract_section = true
          next
        end
        
        # Stop when we hit another ## section or Resources
        if in_abstract_section && (stripped.start_with?('## ') && stripped != '## Abstract')
          break
        end
        
        # Collect abstract content (skip empty lines at start)
        if in_abstract_section && !stripped.empty?
          abstract_lines << stripped
        elsif in_abstract_section && !abstract_lines.empty? && stripped.empty?
          # Allow empty lines within the abstract, but stop at double empty lines
          abstract_lines << ''
        end
      end
      
      abstract_lines.join(' ').gsub(/\s+/, ' ').strip
    end
    
    def extract_description_legacy(content)
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
    
    def extract_abstract_legacy(content)
      return '' unless content
      
      lines = content.to_s.split("\n")
      
      # Find content after the presentation context but before Resources
      abstract_lines = []
      found_presentation_context = false
      in_abstract = false
      
      lines.each do |line|
        stripped = line.strip
        
        # Skip title line
        next if stripped.start_with?('# ')
        
        # Skip metadata lines
        next if stripped.match(/^\*\*\w+:\*\*/)
        
        # Skip source comment
        next if stripped.start_with?('<!-- Source:')
        
        # Check if this is the start of presentation context line
        if stripped.start_with?('A presentation at')
          found_presentation_context = true
          next
        end
        
        # Skip lines that are part of the presentation context (including the liquid template)
        if found_presentation_context && !in_abstract
          if stripped.empty?
            # Empty line after presentation context - start collecting abstract next
            in_abstract = true
            next
          elsif stripped.include?('{{ site.speaker') || stripped.include?('June 2025') || stripped.include?('Luxembourg')
            # Still part of presentation context
            next
          else
            # This must be the start of the actual abstract
            in_abstract = true
          end
        end
        
        # Stop at Resources section
        break if stripped.start_with?('## Resources')
        
        # Collect abstract content
        if in_abstract && !stripped.empty?
          abstract_lines << stripped
        end
      end
      
      # Join and clean up the abstract
      abstract_text = abstract_lines.join(' ')
      
      # Clean up extra spaces and return
      abstract_text.gsub(/\s+/, ' ').strip
    end
    
    def extract_resources_from_content(content)
      return '' unless content
      
      lines = content.to_s.split("\n")
      resources_start = lines.find_index { |line| line.strip.start_with?('## Resources') }
      return '' unless resources_start
      
      resource_lines = lines[(resources_start + 1)..-1] || []
      resource_lines.join("\n").strip
    end
    
    def extract_and_process_presentation_context(content, site)
      return '' unless content
      
      lines = content.to_s.split("\n")
      
      # Find the "A presentation at..." section
      presentation_start = lines.find_index { |line| line.strip.start_with?('A presentation at') }
      return '' unless presentation_start
      
      # Extract the presentation context (usually spans multiple lines)
      context_lines = []
      (presentation_start..lines.length-1).each do |i|
        line = lines[i].strip
        
        # Stop at next section (usually ## Resources)
        break if line.start_with?('##') || line.start_with?('# ')
        
        # Include non-empty lines
        if !line.empty?
          context_lines << line
        elsif !context_lines.empty?
          # Stop at first empty line after we've collected content
          break
        end
      end
      
      # Join the context and process liquid variables
      raw_context = context_lines.join(' ')
      
      # Process liquid variables using Jekyll's liquid renderer
      begin
        liquid_template = Liquid::Template.parse(raw_context)
        processed_context = liquid_template.render('site' => site.site_payload['site'])
        return processed_context
      rescue => e
        # Fallback to raw context if liquid processing fails
        puts "DEBUG: Liquid processing failed for presentation context: #{e.message}"
        return raw_context
      end
    end
  end
end
