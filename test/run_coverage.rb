#!/usr/bin/env ruby
# frozen_string_literal: true

# Enable coverage
ENV['COVERAGE'] = 'true'

# Load SimpleCov before any application code
require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'
  add_filter '/.bundle/'
  add_filter '/.jekyll-cache/'
  add_filter '/_site/'
  add_filter '/_test_site/'
  
  add_group 'Renderers', 'lib/*renderer*.rb'
  add_group 'Migration', 'migrate_talk.rb'
  add_group 'Utilities', 'lib/utils'
  add_group 'Models', 'lib/models'
  add_group 'Plugins', '_plugins'
  
  # Track coverage for key files
  track_files '{lib,_plugins}/**/*.rb'
  track_files 'migrate_talk.rb'
end

puts "📊 SimpleCov Coverage Analysis"
puts "=" * 60

# Determine which tests to run
test_category = ARGV[0] || 'unit'

case test_category
when 'unit'
  test_files = Dir.glob('test/impl/unit/*_test.rb')
when 'integration'
  test_files = Dir.glob('test/impl/integration/*_test.rb')
when 'all'
  test_files = Dir.glob('test/**/*_test.rb').reject { |f| f.include?('fixtures') }
else
  puts "Unknown category: #{test_category}"
  puts "Usage: ruby test/run_coverage.rb [unit|integration|all]"
  exit 1
end

puts "Running #{test_files.length} test files..."
puts

# Run tests
test_files.each do |file|
  require_relative "../#{file}"
end

puts
puts "=" * 60
puts "📊 Coverage report generated in coverage/index.html"
puts "=" * 60
