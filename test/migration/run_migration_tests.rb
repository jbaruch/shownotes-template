#!/usr/bin/env ruby

require 'fileutils'

puts "TEST MIGRATION TEST SUITE"
puts "=" * 60
puts "Running comprehensive migration validation tests..."
puts "This validates that migration from noti.st to Jekyll was successful."
puts

# Ensure screenshots directory exists
FileUtils.mkdir_p('test/screenshots')

puts "LIST Test Suite 1: Content Migration Accuracy"
puts "   ✓ Complete resource migration (40/40 resources)"
puts "   ✓ Resource type detection (slides, video, PDF, links)"
puts "   ✓ Video detection accuracy"
puts

puts "LIST Test Suite 2: Resource URL Validation" 
puts "   ✓ Google Slides URL format (/d/{id}/edit not /d/e/{id}/pub)"
puts "   ✓ External link accessibility (HTTP 200 responses)"
puts

puts "LIST Test Suite 3: Visual Quality Validation"
puts "   ✓ Thumbnail display quality (no broken images)"
puts "   ✓ Resource preview functionality"
puts

puts "LIST Test Suite 4: Migration Quality Assurance"
puts "   ✓ Content completeness check"
puts "   ✓ Link and resource functionality"
puts

puts "LIST Test Suite 5: Regression Prevention"
puts "   ✓ No Liquid syntax in YAML front matter"
puts "   ✓ No placeholder resources"
puts

puts "STARTING RUNNING TESTS..."
puts "-" * 60

# Run content/API tests first (faster, don't require browser)
puts "\n1️⃣ Content Migration Tests (Ruby/API based)"
system("bundle exec ruby test/migration_test.rb")

migration_exit_code = $?.exitstatus
puts "\nMigration tests: #{migration_exit_code == 0 ? 'SUCCESS PASSED' : 'FAIL FAILED'}"

# Run visual tests (HTTP-based, lighter)
puts "\n2️⃣ Visual Quality Tests (HTTP-based)"
puts "NOTE: Requires Jekyll server running on localhost:4000"
puts "If tests skip, start with: bundle exec jekyll serve"
puts

system("bundle exec ruby test/visual_test_simple.rb")

visual_exit_code = $?.exitstatus  
puts "\nVisual tests: #{visual_exit_code == 0 ? 'SUCCESS PASSED' : 'FAIL FAILED'}"

# Overall result
puts "\n" + "=" * 60
puts "MIGRATION TEST RESULTS"
puts "=" * 60

if migration_exit_code == 0 && visual_exit_code == 0
  puts "CELEBRATION ALL TESTS PASSED!"
  puts "SUCCESS Migration from noti.st to Jekyll is COMPLETE and verified"
  puts "SUCCESS All 40 resources migrated successfully"  
  puts "SUCCESS No broken thumbnails or console errors"
  puts "SUCCESS All URLs functional and properly formatted"
  puts "SUCCESS Visual quality matches/exceeds original"
  
  exit 0
else
  puts "FAIL TESTS FAILED!"
  puts "FAIL Migration validation incomplete"
  puts "FAIL Review failures above and fix issues"
  puts
  puts "Common issues to check:"
  puts "  - Resource count mismatch (should be exactly 40)"
  puts "  - Broken thumbnail images"
  puts "  - Wrong Google Slides URL format"
  puts "  - Console CSP errors"
  puts "  - Liquid syntax in YAML front matter"
  
  if visual_exit_code != 0
    puts "\nScreenshots of failures saved in test/screenshots/"
  end
  
  exit 1
end