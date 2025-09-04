#!/usr/bin/env ruby

require 'jekyll'

config = Jekyll.configuration({'source' => '.', 'destination' => './_site'})
site = Jekyll::Site.new(config)
site.process

robocoders = site.collections['talks'].docs.find { |doc| doc.basename.include?('robocoders') }
technical = site.collections['talks'].docs.find { |doc| doc.basename.include?('technical-enshittification') }

puts "RoboCoders extracted_slides: #{robocoders.data['extracted_slides'].inspect}"
puts "Technical extracted_slides: #{technical.data['extracted_slides'].inspect}"
puts
puts "RoboCoders extracted_video: #{robocoders.data['extracted_video'].inspect}"  
puts "Technical extracted_video: #{technical.data['extracted_video'].inspect}"
