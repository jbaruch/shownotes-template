#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

# Migration script to convert from old verbose YAML format to new simplified format
class FormatMigrator
  def migrate_file(file_path)
    content = File.read(file_path)
    
    # Split frontmatter and content
    parts = content.split('---', 3)
    return unless parts.length >= 3
    
    frontmatter = YAML.load(parts[1])
    markdown_content = parts[2].strip
    
    # Convert to new format
    new_frontmatter = {
      'title' => frontmatter['title'],
      'conference' => frontmatter['conference'],
      'date' => frontmatter['date']
    }
    
    # Extract slides and video from old resources format
    if frontmatter['resources']
      if frontmatter['resources'].is_a?(Array)
        # Handle array format
        frontmatter['resources'].each do |resource|
          case resource['type']
          when 'slides'
            new_frontmatter['slides'] = resource['url']
          when 'video'
            new_frontmatter['video'] = resource['url']
          end
        end
      elsif frontmatter['resources'].is_a?(Hash)
        # Handle hash format
        new_frontmatter['slides'] = frontmatter['resources']['slides']['url'] if frontmatter['resources']['slides']
        new_frontmatter['video'] = frontmatter['resources']['video']['url'] if frontmatter['resources']['video']
      end
    end
    
    # Remove nil values
    new_frontmatter.compact!
    
    # Generate new file content
    new_content = "---\n#{new_frontmatter.to_yaml.gsub(/^---\n/, '')}---\n\n#{markdown_content}"
    
    # Backup original
    File.write("#{file_path}.backup", content)
    
    # Write new format
    File.write(file_path, new_content)
    
    puts "✅ Migrated #{file_path}"
    puts "   📄 Backup saved as #{file_path}.backup"
  end
  
  def migrate_all_talks
    Dir['_talks/*.md'].each do |file|
      migrate_file(file)
    end
  end
end

if __FILE__ == $0
  migrator = FormatMigrator.new
  
  if ARGV.empty?
    puts "Migrating all talk files..."
    migrator.migrate_all_talks
  else
    ARGV.each do |file|
      migrator.migrate_file(file)
    end
  end
  
  puts "\n🎉 Migration complete!"
  puts "📝 Old format backed up with .backup extension"
  puts "🔍 Review changes and delete .backup files when satisfied"
end
