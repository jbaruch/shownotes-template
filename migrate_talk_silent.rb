#!/usr/bin/env ruby

# Suppress all warnings and stderr output to create a completely clean migration experience
$VERBOSE = nil

# Load the original migration script
require_relative 'migrate_talk'

# Redirect stderr to /dev/null to suppress liquid warnings
$stderr.reopen('/dev/null', 'w')

# Run the migration with the same arguments
TalkMigrator.new(ARGV[0], skip_tests: ARGV.include?('--skip-tests')).migrate
