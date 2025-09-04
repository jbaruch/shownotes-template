#!/usr/bin/env ruby

# Suppress Ruby warnings for dependencies like liquid 4.0.4
$VERBOSE = nil

# Load the original migration script
load File.expand_path('../migrate_talk.rb', __FILE__)
