#!/usr/bin/env ruby

require_relative 'run_tests'

# Convenience runner for speaker configuration tests only
# This is a wrapper around the main test runner
if __FILE__ == $0
  puts "🎤 Running Speaker Configuration Test Suite"
  ShownotesTestRunner.run(category: 'speaker')
end
    
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
