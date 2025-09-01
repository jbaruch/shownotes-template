#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'nokogiri'

# Load the test methods
require_relative 'test/migration/migration_test'

class MigrationDebugger < MigrationTest
  def debug_resource_extraction
    setup
    
    # Get the talk data
    talk_name = '2025-06-20-voxxed-luxembourg-technical-enshittification'
    talk_data = @talks[talk_name]
    
    puts "=== DEBUGGING RESOURCE EXTRACTION ==="
    puts "Talk: #{talk_name}"
    puts "Source URL: #{talk_data[:source_url]}"
    puts
    
    # Extract source resources
    puts "=== EXTRACTING SOURCE RESOURCES ==="
    source_resources = extract_resources_from_source(talk_data[:source_url])
    puts "Source resources found: #{source_resources.length}"
    puts "Source resources:"
    source_resources.each_with_index do |resource, i|
      puts "  #{i+1}. #{resource[:text]} -> #{resource[:url]}"
    end
    puts
    
    # Count migrated resources
    puts "=== COUNTING MIGRATED RESOURCES ==="
    migrated_count = count_resources_in_content(talk_data[:raw_content])
    puts "Migrated resources found: #{migrated_count}"
    
    # Show the actual migrated content resources
    content = talk_data[:raw_content]
    markdown_links = content.scan(/\[([^\]]+)\]\(([^)]+)\)/)
    puts "Migrated resources:"
    markdown_links.each_with_index do |(text, url), i|
      next if url.start_with?('#') || text.downcase.include?('back to') || 
              text.downcase.include?('slides') || text.downcase.include?('presentation')
      puts "  #{i+1}. #{text} -> #{url}"
    end
  end
end

debugger = MigrationDebugger.new
debugger.debug_resource_extraction
