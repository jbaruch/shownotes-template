require 'rake/testtask'

# Default task
task default: :test

# Test task for all tests
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/impl/**/*_test.rb'
  t.verbose = true
end

# Individual test categories
namespace :test do
  desc "Run unit tests"
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'test'
    t.pattern = 'test/impl/unit/*_test.rb'
    t.verbose = true
  end

  desc "Run integration tests"
  Rake::TestTask.new(:integration) do |t|
    t.libs << 'test'
    t.pattern = 'test/impl/integration/*_test.rb'
    t.verbose = true
  end

  desc "Run performance tests"
  Rake::TestTask.new(:performance) do |t|
    t.libs << 'test'
    t.pattern = 'test/impl/performance/*_test.rb'
    t.verbose = true
  end

  desc "Run E2E tests"
  Rake::TestTask.new(:e2e) do |t|
    t.libs << 'test'
    t.pattern = 'test/impl/e2e/*_test.rb'
    t.verbose = true
  end

  desc "Run all tests with summary"
  task :all do
    puts "Running comprehensive test suite..."
    puts "=" * 50
    
    # Track results
    results = {}
    
    %w[unit integration performance e2e].each do |category|
      puts "\n>>> #{category.upcase} TESTS <<<"
      puts "-" * 30
      
      start_time = Time.now
      result = system("bundle exec rake test:#{category}")
      end_time = Time.now
      
      results[category] = {
        success: result,
        time: (end_time - start_time).round(2)
      }
    end
    
    # Summary
    puts "\n" + "=" * 50
    puts "TEST SUMMARY"
    puts "=" * 50
    
    total_time = 0
    success_count = 0
    
    results.each do |category, data|
      status = data[:success] ? "✅ PASS" : "❌ FAIL"
      puts "#{category.capitalize.ljust(12)}: #{status} (#{data[:time]}s)"
      total_time += data[:time]
      success_count += 1 if data[:success]
    end
    
    puts "-" * 50
    puts "Total time: #{total_time}s"
    puts "Success rate: #{success_count}/#{results.size} (#{(success_count.to_f / results.size * 100).round}%)"
    
    if success_count == results.size
      puts "\n🎉 ALL TESTS PASSED! 🎉"
      exit 0
    else
      puts "\n❌ Some tests failed"
      exit 1
    end
  end
end

# Quick test commands
desc "Quick test run (essential tests only)"
task :quick do
  essential_tests = [
    'test/impl/unit/comprehensive_scenarios_test.rb',
    'test/impl/integration/jekyll_build_test.rb',
    'test/impl/e2e/user_workflow_test.rb'
  ]
  
  puts "Running essential tests..."
  essential_tests.each do |test_file|
    puts ">>> #{File.basename(test_file)}"
    system("bundle exec ruby -Itest #{test_file}") || exit(1)
  end
  puts "✅ Essential tests passed!"
end

# Help task
desc "Show available test commands"
task :help do
  puts <<~HELP
    Available test commands:
    
    rake test           - Run all tests
    rake test:all       - Run all tests with detailed summary
    rake test:unit      - Run unit tests only
    rake test:integration - Run integration tests only  
    rake test:performance - Run performance tests only
    rake test:e2e       - Run E2E tests only
    rake quick          - Run essential tests only
    rake help           - Show this help
    
    Examples:
      bundle exec rake test
      bundle exec rake test:all
      bundle exec rake quick
  HELP
end