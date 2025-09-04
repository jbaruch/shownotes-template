#!/usr/bin/env ruby

require 'jekyll'

config = Jekyll.configuration({'source' => '.', 'destination' => './_site'})
site = Jekyll::Site.new(config)
site.process

puts "Available talks:"
site.collections['talks'].docs.each { |doc| puts "- #{doc.data['title'] || doc.basename}" }
puts

robocoders = site.collections['talks'].docs.find { |doc| doc.basename.include?('robocoders') }
technical = site.collections['talks'].docs.find { |doc| doc.basename.include?('technical-enshittification') }

puts "RoboCoders found: #{!!robocoders}"
puts "Technical found: #{!!technical}"

if robocoders
  puts "RoboCoders thumbnail_url: #{robocoders.data['thumbnail_url'].inspect}"
end
if technical  
  puts "Technical thumbnail_url: #{technical.data['thumbnail_url'].inspect}"
end
