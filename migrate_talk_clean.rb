#!/usr/bin/env ruby --disable-frozen-string-literal

# This script runs the migration with frozen string literal warnings disabled
# This is cleaner than trying to suppress stderr or individual warnings

# Load the original migration script
require_relative 'migrate_talk'

# Run the migration with the same arguments
TalkMigrator.new(ARGV[0], skip_tests: ARGV.include?('--skip-tests')).migrate
