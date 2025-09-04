#!/usr/bin/env ruby

require 'jekyll'

config = Jekyll.configuration({'source' => '.', 'destination' => './_site'})
site = Jekyll::Site.new(config)
site.process

talk = site.collections['talks'].docs.find { |doc| doc.data['title'].to_s.include?('Technical Enshittification') }

puts "Front matter extracted_abstract:"
puts talk.data['extracted_abstract'].inspect
puts
puts "Front matter extracted_description:"
puts talk.data['extracted_description'].inspect
