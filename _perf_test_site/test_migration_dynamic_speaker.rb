#!/usr/bin/env ruby

# Test script to verify migration script generates dynamic speaker references

require_relative 'migrate_talk'

# Create a mock migrator to test the new methods
class TestMigrator < TalkMigrator
  def initialize
    @talk_data = {
      title: "Test Talk Title",
      conference: "Test Conference 2025",
      date: "2025-03-15",
      location: "San Francisco, CA",
      abstract: "This is a test abstract for the talk."
    }
    @resources = [
      { 'type' => 'slides', 'url' => 'https://drive.google.com/file/d/test123/view', 'title' => 'Test Slides' },
      { 'type' => 'video', 'url' => 'https://youtube.com/watch?v=test456', 'title' => 'Test Video' },
      { 'type' => 'resource', 'url' => 'https://example.com/resource1', 'title' => 'Test Resource 1' }
    ]
  end
  
  # Public accessor for testing
  def test_generate_presentation_context
    generate_presentation_context
  end
  
  def test_generate_clean_markdown_body
    generate_clean_markdown_body
  end
end

puts "🧪 Testing Migration Script Dynamic Speaker Features"
puts "=" * 60

migrator = TestMigrator.new

puts "\n1️⃣ Testing presentation context generation..."
context = migrator.test_generate_presentation_context
puts "Generated context:"
puts context
puts

# Check if dynamic speaker reference is included
if context.include?("{{ site.speaker.display_name | default: site.speaker.name }}")
  puts "✅ PASS: Dynamic speaker reference found"
else
  puts "❌ FAIL: Dynamic speaker reference not found"
  puts "Expected: {{ site.speaker.display_name | default: site.speaker.name }}"
end

puts "\n2️⃣ Testing full markdown body generation..."
body = migrator.test_generate_clean_markdown_body
puts "Generated body:"
puts body
puts

# Check if dynamic speaker reference is included in the full body
if body.include?("{{ site.speaker.display_name | default: site.speaker.name }}")
  puts "✅ PASS: Dynamic speaker reference found in full body"
else
  puts "❌ FAIL: Dynamic speaker reference not found in full body"
end

# Check if structure is correct
expected_elements = [
  "# Test Talk Title",
  "**Conference:** Test Conference 2025",
  "**Date:** 2025-03-15", 
  "**Slides:** [View Slides]",
  "**Video:** [Watch Video]",
  "A presentation at Test Conference 2025",
  "March 2025 in",
  "San Francisco, CA by",
  "## Resources"
]

puts "\n3️⃣ Checking content structure..."
missing_elements = expected_elements.reject { |element| body.include?(element) }

if missing_elements.empty?
  puts "✅ PASS: All expected content elements found"
else
  puts "❌ FAIL: Missing content elements:"
  missing_elements.each { |element| puts "  - #{element}" }
end

puts "\n" + "=" * 60
puts "🎯 Test completed. Check results above."
