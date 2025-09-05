#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

# Main test runner for the shownotes test suite
class ShownotesTestRunner
  def self.run(options = {})
    puts "🧪 Running Shownotes Test Suite"
    puts "=" * 60
    
    test_category = options[:category] || 'default'
    test_files = discover_test_files(test_category)
    
    puts "📂 Test Category: #{test_category}"
    
    if test_category == 'default'
      puts "ℹ️  Running standard tests (excludes migration/Google Drive - use -c all for everything)"
    elsif test_category == 'all'
      puts "⚠️  Running ALL tests including migration (requires Google Drive API access)"
    elsif test_category == 'migration'
      puts "⚠️  Migration tests require Google Drive API access (Google API.json file)"
    end
    
    puts "📋 Found #{test_files.length} test files:"
    test_files.each { |file| puts "   #{file}" }
    puts
    
    # Initialize aggregation counters
    total_runs = 0
    total_assertions = 0
    total_failures = 0
    total_errors = 0
    total_skips = 0
    failed_tests = []
    error_tests = []
    skipped_tests = []
    
    # Run each test file separately to avoid loading conflicts
    test_files.each do |file|
      puts "Running #{file}..."
      output = `bundle exec ruby #{file} 2>&1`
      puts output
      
      # Parse minitest output for aggregation
      if match = output.match(/(\d+) runs?, (\d+) assertions?, (\d+) failures?, (\d+) errors?, (\d+) skips?/)
        runs = match[1].to_i
        assertions = match[2].to_i
        failures = match[3].to_i
        errors = match[4].to_i
        skips = match[5].to_i
        
        total_runs += runs
        total_assertions += assertions
        total_failures += failures
        total_errors += errors
        total_skips += skips
        
        # Track which files had issues
        failed_tests << file if failures > 0
        error_tests << file if errors > 0
        skipped_tests << file if skips > 0
      end
    end
    
    puts
    puts "=" * 60
    puts "📊 AGGREGATE TEST RESULTS"
    puts "=" * 60
    puts "Total Runs:       #{total_runs}"
    puts "Total Assertions: #{total_assertions}"
    puts "Total Failures:   #{total_failures}"
    puts "Total Errors:     #{total_errors}"
    puts "Total Skips:      #{total_skips}"
    puts
    
    # Show detailed breakdown of issues
    if failed_tests.any?
      puts "❌ FAILED TESTS:"
      failed_tests.each { |file| puts "   #{file}" }
      puts
    end
    
    if error_tests.any?
      puts "💥 ERROR TESTS:"
      error_tests.each { |file| puts "   #{file}" }
      puts
    end
    
    if skipped_tests.any?
      puts "⏭️  SKIPPED TESTS:"
      skipped_tests.each { |file| puts "   #{file}" }
      puts
    end
    
    if total_failures == 0 && total_errors == 0
      puts "✅ ALL TESTS PASSED"
    else
      puts "❌ TESTS FAILED: #{total_failures} failures, #{total_errors} errors"
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
      # All tests INCLUDING migration and Google Drive tests
      Dir.glob('test/**/*_test.rb').reject { |f| f.include?('fixtures') }
    when 'default'
      # Default tests EXCLUDING migration and Google Drive tests (for general users)
      all_files = Dir.glob('test/**/*_test.rb').reject { |f| f.include?('fixtures') }
      migration_files = Dir.glob('test/migration/*_test.rb') + Dir.glob('test/external/google_drive*_test.rb') + ['test/migration_test.rb']
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
      puts "   all         - All tests including migration (requires Google Drive API)"
      puts "   default     - Standard tests excluding migration (default for most users)"
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
      puts "  all         - All tests including migration (requires Google Drive API)"
      puts "  default     - Standard tests excluding migration (default for most users)"
      puts
      puts "Examples:"
      puts "  #{$0}                    # Run standard tests (excludes migration)"
      puts "  #{$0} -c unit            # Run only unit tests"
      puts "  #{$0} -c all             # Run ALL tests including migration (needs Google API)"
      puts "  #{$0} -c migration       # Run migration tests only (needs Google API)"
      exit
    end
  end.parse!
  
  ShownotesTestRunner.run(options)
end
