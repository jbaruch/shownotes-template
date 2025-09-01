#!/usr/bin/env ruby
# frozen_string_literal: true

# Legacy test runner - redirects to the new unified runner
require_relative 'run_tests'

if __FILE__ == $0
  puts "⚠️  Using legacy test runner. Consider using 'test/run_tests.rb' directly."
  puts "ℹ️  Running all tests except migration (use 'test/run_tests.rb -c migration' for migration tests)"
  ShownotesTestRunner.run(category: 'all')
end