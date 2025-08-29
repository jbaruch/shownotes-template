#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/reporters'

# Configure test output
Minitest::Reporters.use! [
  Minitest::Reporters::DefaultReporter.new(color: true, slow_threshold: 5),
  Minitest::Reporters::JUnitReporter.new('test/reports')
]

class SpeakerConfigurationTestRunner
  def self.run_all_tests
    puts "\n" + "="*80
    puts "SPEAKER CONFIGURATION COMPREHENSIVE TEST SUITE"
    puts "="*80
    
    # Create reports directory
    FileUtils.mkdir_p('test/reports')
    
    test_files = [
      'test/impl/unit/speaker_configuration_test.rb',
      'test/impl/integration/speaker_configuration_integration_test.rb',
      'test/impl/integration/speaker_configuration_visual_test.rb'
    ]
    
    puts "\nTest files to execute:"
    test_files.each { |f| puts "  - #{f}" }
    puts "\n" + "-"*80
    
    # Check if all test files exist
    missing_files = test_files.reject { |f| File.exist?(f) }
    unless missing_files.empty?
      puts "ERROR: Missing test files:"
      missing_files.each { |f| puts "  - #{f}" }
      exit 1
    end
    
    # Load and run tests
    start_time = Time.now
    
    test_files.each do |test_file|
      puts "\nLoading: #{test_file}"
      require_relative "../#{test_file.sub('test/', '')}"
    end
    
    # Run the tests
    result = Minitest.run([])
    
    end_time = Time.now
    duration = end_time - start_time
    
    puts "\n" + "="*80
    puts "TEST SUITE COMPLETION SUMMARY"
    puts "="*80
    puts "Duration: #{duration.round(2)} seconds"
    puts "Result: #{result == 0 ? 'SUCCESS' : 'FAILURE'}"
    
    if result == 0
      puts "\n🎉 All speaker configuration tests passed!"
      puts "\nTest Coverage Verified:"
      puts "  ✓ Unit tests: Avatar priority logic, social media generation, edge cases"
      puts "  ✓ Integration tests: Jekyll builds, real rendering, error handling"
      puts "  ✓ Visual tests: Screenshots, responsive layout, UI verification"
    else
      puts "\n❌ Some tests failed. Check the output above for details."
      puts "\nRecommended actions:"
      puts "  1. Review failed test details"
      puts "  2. Check Jekyll configuration"
      puts "  3. Verify speaker configuration format"
      puts "  4. Ensure all dependencies are installed"
    end
    
    puts "\n" + "="*80
    
    exit result
  end
end

# Auto-run tests if this file is executed directly
if __FILE__ == $0
  SpeakerConfigurationTestRunner.run_all_tests
end
