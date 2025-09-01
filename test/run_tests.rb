#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require 'optparse'

# Main test runner for the shownotes test suite
class ShownotesTestRunner
  def self.run(options = {})
    puts "🧪 Running Shownotes Test Suite"
    puts "=" * 60
    
    test_category = options[:category] || 'all'
    test_files = discover_test_files(test_category)
    
    puts "📂 Test Category: #{test_category}"
    puts "📋 Found #{test_files.length} test files:"
    test_files.each { |file| puts "   #{file}" }
    puts
    
    # Load and run test files
    test_files.each { |file| require_relative "../#{file}" }
    
    puts "✅ Test suite completed"
  end
  
  private
  
  def self.discover_test_files(category)
    case category.downcase
    when 'unit'
      Dir.glob('test/impl/unit/*_test.rb')
    when 'integration'
      Dir.glob('test/impl/integration/*_test.rb')
    when 'e2e'
      Dir.glob('test/impl/e2e/*_test.rb')
    when 'migration'
      Dir.glob('test/migration/*_test.rb')
    when 'external'
      Dir.glob('test/external/*_test.rb')
    when 'tools'
      Dir.glob('test/tools/*_test.rb')
    when 'performance'
      Dir.glob('test/impl/performance/*_test.rb')
    when 'speaker'
      [
        'test/impl/unit/speaker_configuration_test.rb',
        'test/impl/integration/speaker_configuration_integration_test.rb',
        'test/impl/integration/speaker_configuration_visual_test.rb'
      ].select { |f| File.exist?(f) }
    when 'all'
      Dir.glob('test/**/*_test.rb').reject { |f| f.include?('fixtures') }
    else
      puts "❌ Unknown test category: #{category}"
      puts "📖 Available categories: unit, integration, e2e, migration, external, tools, performance, speaker, all"
      exit 1
    end
  end
end

# Command line interface
if __FILE__ == $0
  options = {}
  
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    
    opts.on('-c', '--category CATEGORY', 'Test category to run (unit, integration, e2e, migration, external, tools, performance, speaker, all)') do |category|
      options[:category] = category
    end
    
    opts.on('-h', '--help', 'Show help') do
      puts opts
      exit
    end
  end.parse!
  
  ShownotesTestRunner.run(options)
end
