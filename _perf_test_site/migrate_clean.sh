#!/bin/bash

# Clean migration wrapper that disables frozen string literal warnings
# This eliminates the flood of liquid 4.0.4 warnings

exec bundle exec ruby --disable-frozen-string-literal migrate_talk.rb "$@"
