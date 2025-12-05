#!/usr/bin/env ruby
# frozen_string_literal: true

# Enable coverage
ENV['COVERAGE'] = 'true'

# Load SimpleCov before any application code
require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'
  
  add_group 'Migration Script', 'migrate_talk.rb'
  
  track_files 'migrate_talk.rb'
end

puts "📊 Migration Script Coverage Analysis"
puts "=" * 60

# Run migration tests
require_relative '../migration/migration_test.rb'

puts
puts "=" * 60
puts "📊 Coverage report generated in coverage/index.html"
puts "=" * 60
