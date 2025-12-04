# frozen_string_literal: true

# Filename generation utilities for consistent, readable filenames
module FilenameGenerator
  # Generate a URL-safe slug from text
  def generate_slug(text, max_length: 50)
    return '' if text.nil? || text.to_s.strip.empty?
    
    slug = text.to_s.downcase
    # Replace non-alphanumeric characters with hyphens
    slug = slug.gsub(/[^a-z0-9]+/, '-')
    # Remove leading/trailing hyphens
    slug = slug.gsub(/^-+|-+$/, '')
    
    # Truncate to max length at word boundary
    if slug.length > max_length
      truncated = slug[0...max_length]
      last_dash = truncated.rindex('-')
      slug = if last_dash && last_dash > max_length * 0.6
               truncated[0...last_dash]
             else
               truncated.gsub(/-+$/, '')
             end
    end
    
    slug
  end
  
  # Generate a smart conference slug (removes common words, keeps meaningful parts)
  def generate_conference_slug(conference, max_parts: 3)
    return '' if conference.nil? || conference.to_s.strip.empty?
    
    slug = conference.downcase
    
    # Remove common conference words to shorten
    slug = slug.gsub(/\b(conference|days?|summit|tech|technology|developers?|dev|meetup|event|annual|international|world|global)\b/, '')
    
    # Clean up and extract meaningful parts
    slug = slug.gsub(/[^a-z0-9\s]+/, ' ').strip.gsub(/\s+/, '-')
    
    # Split into parts and take meaningful ones
    parts = slug.split('-').reject(&:empty?)
    
    # Smart selection of parts (prefer location/brand over year/generic terms)
    selected_parts = []
    year_pattern = /^20\d{2}$/
    
    parts.each do |part|
      next if part.length < 2  # Skip very short parts
      next if part.match(year_pattern) && selected_parts.length >= 2  # Skip year if we have enough parts
      selected_parts << part
      break if selected_parts.length >= max_parts
    end
    
    selected_parts.join('-')
  end
  
  # Generate a smart title slug (removes stop words, keeps technical terms)
  def generate_title_slug(title, max_length: 50)
    return '' if title.nil? || title.to_s.strip.empty?
    
    slug = title.downcase
    
    # Remove common stop words but keep technical terms
    stop_words = %w[a an and the or but in on at to for of with from by is are was were be been being have has had do does did will would could should can may might must shall why how what when where who]
    
    # Clean and split into words
    words = slug.gsub(/[^a-z0-9\s]+/, ' ').strip.split(/\s+/)
    
    # Keep important words (not stop words, or if they're technical terms)
    important_words = words.select do |word|
      word.length > 2 && (!stop_words.include?(word) || word.length > 8)
    end
    
    # If we filtered too aggressively, keep some stop words
    if important_words.length < 2 && words.length > important_words.length
      important_words = words.reject { |w| stop_words.include?(w) && w.length <= 3 }
    end
    
    # Join and apply max length
    result = important_words.join('-')
    
    # Truncate if needed
    if result.length > max_length
      truncated = result[0...max_length]
      last_dash = truncated.rindex('-')
      result = if last_dash && last_dash > max_length * 0.6
                 truncated[0...last_dash]
               else
                 truncated.gsub(/-+$/, '')
               end
    end
    
    result
  end
  
  # Generate a complete talk filename (YYYY-MM-DD-conference-title.md)
  def generate_talk_filename(date, conference, title, extension: '.md')
    date_part = date.to_s
    conference_slug = generate_conference_slug(conference)
    title_slug = generate_title_slug(title)
    
    # Ensure reasonable total length (prefer under 80 characters)
    base_length = date_part.length + 1 + conference_slug.length + 1 + extension.length
    available_for_title = 75 - base_length
    
    if title_slug.length > available_for_title && available_for_title > 15
      title_slug = generate_title_slug(title, max_length: available_for_title)
    end
    
    "#{date_part}-#{conference_slug}-#{title_slug}#{extension}"
  end
  
  # Generate thumbnail filename
  def generate_thumbnail_filename(talk_slug_or_options, extension: '.png')
    if talk_slug_or_options.is_a?(Hash)
      # Generate from components
      date = talk_slug_or_options[:date]
      conference = talk_slug_or_options[:conference]
      title = talk_slug_or_options[:title]
      talk_slug = generate_talk_filename(date, conference, title, extension: '')
    else
      # Use provided slug
      talk_slug = talk_slug_or_options.to_s
    end
    
    "#{talk_slug}-thumbnail#{extension}"
  end
  
  # Sanitize filename by removing invalid characters
  def sanitize_filename(filename)
    return '' if filename.nil? || filename.to_s.strip.empty?
    
    # Remove or replace invalid filename characters
    sanitized = filename.to_s.gsub(/[\/\\:*?"<>|]/, '-')
    # Remove multiple consecutive hyphens
    sanitized = sanitized.gsub(/-+/, '-')
    # Remove leading/trailing hyphens
    sanitized.gsub(/^-+|-+$/, '')
  end
end
