#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

# Main test runner for the shownotes test suite
class ShownotesTestRunner
  def self.run(options = {})
    puts "🧪 Running Shownotes Test Suite"
    puts "=" * 60
    
    test_category = options[:category] || 'all'
    test_files = discover_test_files(test_category)
    
    puts "📂 Test Category: #{test_category}"
    
    if test_category == 'all'
      puts "ℹ️  Running all tests except migration (use -c migration for migration tests)"
    elsif test_category == 'migration'
      puts "⚠️  Migration tests require Google Drive API access (Google API.json file)"
    end
    
    puts "📋 Found #{test_files.length} test files:"
    test_files.each { |file| puts "   #{file}" }
    puts
    
    # Run each test file separately to avoid loading conflicts
    test_files.each do |file|
      puts "Running #{file}..."
      system("bundle exec ruby #{file}")
    end
    
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
      # All migration-related tests (requires Google Drive API access)
      migration_files = []
      migration_files.concat(Dir.glob('test/migration/*_test.rb'))
      migration_files.concat(Dir.glob('test/external/google_drive_integration_test.rb'))
      migration_files
    when 'external'
      # External tests excluding migration-specific ones
      Dir.glob('test/external/*_test.rb').reject { |f| f.include?('google_drive_integration') }
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
      # All tests EXCEPT migration-related ones (for users who don't need migration)
      all_files = Dir.glob('test/**/*_test.rb').reject { |f| f.include?('fixtures') }
      migration_files = Dir.glob('test/migration/*_test.rb') + Dir.glob('test/external/google_drive_integration_test.rb')
      all_files - migration_files
    else
      puts "❌ Unknown test category: #{category}"
      puts "📖 Available categories:"
      puts "   unit        - Unit tests only"
      puts "   integration - Integration tests only" 
      puts "   e2e         - End-to-end tests only"
      puts "   external    - External tests (excluding migration)"
      puts "   tools       - Tool tests only"
      puts "   performance - Performance tests only"
      puts "   speaker     - Speaker configuration tests"
      puts "   migration   - Migration tests (requires Google Drive API)"
      puts "   all         - All tests except migration (default for most users)"
      exit 1
    end
  end
end

# Command line interface
if __FILE__ == $0
  options = {}
  
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    
    opts.on('-c', '--category CATEGORY', 'Test category to run') do |category|
      options[:category] = category
    end
    
    opts.on('-h', '--help', 'Show help') do
      puts opts
      puts
      puts "Available test categories:"
      puts "  unit        - Unit tests only"
      puts "  integration - Integration tests only" 
      puts "  e2e         - End-to-end tests only"
      puts "  external    - External tests (excluding migration)"
      puts "  tools       - Tool tests only"
      puts "  performance - Performance tests only"
      puts "  speaker     - Speaker configuration tests"
      puts "  migration   - Migration tests (requires Google Drive API)"
      puts "  all         - All tests except migration (default for most users)"
      puts
      puts "Examples:"
      puts "  #{$0}                    # Run all non-migration tests"
      puts "  #{$0} -c unit            # Run only unit tests"
      puts "  #{$0} -c migration       # Run migration tests (needs Google API)"
      exit
    end
  end.parse!
  
  ShownotesTestRunner.run(options)
end
