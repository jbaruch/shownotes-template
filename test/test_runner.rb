#!/usr/bin/env ruby
# frozen_string_literal: true

# Legacy test runner - redirects to the new unified runner
require_relative 'run_tests'

if __FILE__ == $0
  puts "⚠️  Using legacy test runner. Consider using 'test/run_tests.rb' directly."
  ShownotesTestRunner.run(category: 'all')
end
    results = run_test_files(test_files)
    
    # Report results
    report_results(results)
    
    # Verify TDD compliance (all tests should fail)
    verify_tdd_compliance(results)
  end

  private

  def self.discover_test_files
    test_files = []
    
    # Unit tests
    test_files.concat(Dir.glob('test/impl/unit/*_test.rb'))
    
    # Integration tests
    test_files.concat(Dir.glob('test/impl/integration/*_test.rb'))
    
    # End-to-end tests
    test_files.concat(Dir.glob('test/impl/e2e/*_test.rb'))
    
    # Performance tests
    test_files.concat(Dir.glob('test/impl/performance/*_test.rb'))
    
    test_files.sort
  end

  def self.run_test_files(test_files)
    results = {
      total_tests: 0,
      total_failures: 0,
      total_errors: 0,
      total_skips: 0,
      test_details: []
    }
    
    test_files.each do |file|
      puts "🔄 Running #{File.basename(file, '.rb')}..."
      
      file_result = run_single_test_file(file)
      
      results[:total_tests] += file_result[:tests]
      results[:total_failures] += file_result[:failures]
      results[:total_errors] += file_result[:errors]
      results[:total_skips] += file_result[:skips]
      results[:test_details] << file_result
    end
    
    results
  end

  def self.run_single_test_file(file)
    basename = File.basename(file, '.rb')
    
    # Actually run the test file with bundle exec
    begin
      result = `cd #{Dir.pwd} && bundle exec ruby "#{file}" 2>&1`
      exit_code = $?.exitstatus
      
      # Parse minitest output for real results
      parse_minitest_output(result, basename, exit_code)
    rescue => e
      {
        file: basename,
        tests: 0,
        failures: 0,
        errors: 1,
        skips: 0,
        details: ["Error running test: #{e.message}"]
      }
    end
  end

  def self.estimate_test_count(test_file_name)
    # Estimate test counts based on test scenarios covered
    case test_file_name
    when 'talk_information_display_test'
      { tests: 5 } # TS-001 through TS-005
    when 'resource_management_test'
      { tests: 5 } # TS-006 through TS-010
    when 'content_rendering_test'
      { tests: 4 } # TS-011 through TS-014
    when 'responsive_design_test'
      { tests: 6 } # TS-015 through TS-018 plus additional responsive tests
    when 'accessibility_test'
      { tests: 8 } # TS-045 through TS-052
    when 'navigation_test'
      { tests: 6 } # TS-022 through TS-027
    when 'site_metadata_test'
      { tests: 8 } # TS-032 through TS-034, TS-039 through TS-044
    when 'security_test'
      { tests: 9 } # TS-053 through TS-061
    when 'error_handling_test'
      { tests: 14 } # TS-062 through TS-075
    when 'validation_test'
      { tests: 10 } # TS-086 through TS-095 plus additional validation scenarios
    when 'frontmatter_validation_test'
      { tests: 12 } # TS-076 through TS-085 plus integration tests
    when 'jekyll_build_test'
      { tests: 8 } # TS-028 through TS-031, TS-064 through TS-067
    when 'user_workflow_test'
      { tests: 6 } # User journey scenarios plus additional workflow tests
    when 'page_load_test'
      { tests: 10 } # TS-035 through TS-038, TS-019 through TS-021 plus performance tests
    when 'comprehensive_scenarios_test'
      { tests: 32 } # Additional scenarios to reach full 121 test scenario coverage
    else
      { tests: 5 } # Default estimate
    end
  end

  def self.generate_failure_details(test_file_name, test_count)
    (1..test_count).map do |i|
      {
        test_name: "test_scenario_#{i}",
        failure_message: "#{test_file_name.gsub('_', ' ').capitalize} method not implemented yet",
        expected_behavior: "Should fail because no implementation exists yet (TDD)"
      }
    end
  end

  def self.report_results(results)
    puts "\n" + "=" * 60
    puts "CHART TEST SUITE RESULTS"
    puts "=" * 60
    
    puts "Total Tests: #{results[:total_tests]}"
    puts "Failures:    #{results[:total_failures]}"
    puts "Errors:      #{results[:total_errors]}"
    puts "Skipped:     #{results[:total_skips]}"
    puts
    
    # Report by test file
    puts "LIST RESULTS BY TEST FILE:"
    results[:test_details].each do |file_result|
      status = file_result[:failures] > 0 ? "FAIL FAIL" : "SUCCESS PASS"
      puts "   #{status} #{file_result[:file]}: #{file_result[:tests]} tests, #{file_result[:failures]} failures"
    end
    puts
  end

  def self.verify_tdd_compliance(results)
    puts "🔍 TEST RESULTS ANALYSIS"
    puts "=" * 30
    
    passing_tests = results[:total_tests] - results[:total_failures] - results[:total_errors]
    
    if results[:total_tests] == 0
      puts "FAIL NO TESTS FOUND"
      puts "   - No tests were executed"
    elsif results[:total_errors] > 0
      puts "FAIL TEST EXECUTION ERRORS"
      puts "   - #{results[:total_errors]} tests had execution errors"
      puts "   - Fix test setup issues before proceeding"
    elsif passing_tests == results[:total_tests]
      puts "SUCCESS ALL TESTS PASSING!"
      puts "   - #{results[:total_tests]} tests passing"
      puts "   - #{results[:total_failures]} tests failing"
      puts "   - Implementation appears complete"
    elsif results[:total_failures] > 0
      puts "⚠️  MIXED RESULTS"
      puts "   - #{passing_tests} tests passing"
      puts "   - #{results[:total_failures]} tests failing"
      puts "   - Partial implementation exists"
    else
      puts "UNKNOWN STATE"
      puts "   - Unexpected test results pattern"
    end
    
    puts
    verify_test_scenario_coverage(results)
  end

  def self.verify_test_scenario_coverage(results)
    puts "📈 TEST SCENARIO COVERAGE VERIFICATION"
    puts "=" * 40
    
    expected_scenarios = 121 # From our test scenarios document
    actual_tests = results[:total_tests]
    
    coverage_percentage = (actual_tests.to_f / expected_scenarios * 100).round(1)
    
    puts "Expected Test Scenarios: #{expected_scenarios} (TS-001 through TS-121)"
    puts "Actual Test Methods:     #{actual_tests}"
    puts "Coverage:                #{coverage_percentage}%"
    
    if coverage_percentage >= 90
      puts "SUCCESS EXCELLENT test scenario coverage!"
    elsif coverage_percentage >= 75
      puts "⚠️  GOOD test scenario coverage, some gaps remain"
    else
      puts "FAIL INSUFFICIENT test scenario coverage"
    end
    
    puts
    puts "TARGET NEXT STEPS:"
    puts "   1. All tests should be failing (SUCCESS if true above)"
    puts "   2. Begin implementation phase to make tests pass"
    puts "   3. Implement only enough code to make each test pass"
    puts "   4. Refactor while maintaining test coverage"
  end
  
  def self.parse_minitest_output(output, basename, exit_code)
    # Parse minitest output like: "5 runs, 17 assertions, 0 failures, 0 errors, 0 skips"
    if match = output.match(/(\d+) runs?, (\d+) assertions?, (\d+) failures?, (\d+) errors?, (\d+) skips?/)
      tests = match[1].to_i
      assertions = match[2].to_i
      failures = match[3].to_i
      errors = match[4].to_i
      skips = match[5].to_i
      
      details = []
      if failures > 0 || errors > 0
        # Extract failure/error details
        failure_section = output.split("Finished in")[0] || ""
        details = failure_section.split("\n").select { |line| 
          line.include?("Failure:") || line.include?("Error:") || line.strip.start_with?("Expected") || line.strip.start_with?("Actual")
        }.map(&:strip).reject(&:empty?)
      end
      
      {
        file: basename,
        tests: tests,
        failures: failures,
        errors: errors,
        skips: skips,
        details: details.empty? ? ["All tests passed!"] : details
      }
    else
      # Fallback if parsing fails
      {
        file: basename,
        tests: 0,
        failures: exit_code != 0 ? 1 : 0,
        errors: exit_code != 0 ? 1 : 0,
        skips: 0,
        details: exit_code != 0 ? ["Test execution failed", output.split("\n").last(3).join("\n")] : ["No test output parsed"]
      }
    end
  end
end

# Run the test suite if this file is executed directly
if __FILE__ == $0
  ShownotesTestRunner.run
end