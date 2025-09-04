#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to download Google thumbnail using various Ruby HTTP methods

require 'net/http'
require 'open-uri'
require 'net/https'
require 'fileutils'

URL = 'https://lh3.googleusercontent.com/d/1dhUS1IMfOIW1YwYRTSUqNTi3HuDjNAaY'
OUTPUT_DIR = 'test_downloads'

FileUtils.mkdir_p(OUTPUT_DIR)

puts "🧪 Testing Ruby HTTP methods to download:"
puts "URL: #{URL}"
puts "=" * 80

# Method 1: Basic Net::HTTP
def test_net_http_basic(url, output_file)
  puts "\n1️⃣ Testing basic Net::HTTP..."
  
  uri = URI.parse(url)
  puts "   Host: #{uri.host}"
  puts "   Port: #{uri.port}"
  puts "   Path: #{uri.path}"
  
  begin
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    response = http.get(uri.path)
    puts "   Response code: #{response.code}"
    puts "   Content-Type: #{response['content-type']}"
    puts "   Content-Length: #{response['content-length']}"
    
    if response.code == '200'
      File.open(output_file, 'wb') { |f| f.write(response.body) }
      puts "   ✅ SUCCESS: #{File.size(output_file)} bytes written"
      return true
    else
      puts "   ❌ FAILED: HTTP #{response.code}"
      return false
    end
  rescue => e
    puts "   ❌ EXCEPTION: #{e.class}: #{e.message}"
    return false
  end
end

# Method 2: Net::HTTP with headers
def test_net_http_headers(url, output_file)
  puts "\n2️⃣ Testing Net::HTTP with browser headers..."
  
  uri = URI.parse(url)
  
  begin
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    
    request = Net::HTTP::Get.new(uri.path)
    request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    request['Accept'] = 'image/webp,image/apng,image/*,*/*;q=0.8'
    request['Accept-Language'] = 'en-US,en;q=0.9'
    request['Accept-Encoding'] = 'gzip, deflate, br'
    request['Connection'] = 'keep-alive'
    request['Referer'] = 'https://drive.google.com/'
    
    response = http.request(request)
    puts "   Response code: #{response.code}"
    puts "   Content-Type: #{response['content-type']}"
    
    if response.code == '200'
      File.open(output_file, 'wb') { |f| f.write(response.body) }
      puts "   ✅ SUCCESS: #{File.size(output_file)} bytes written"
      return true
    else
      puts "   ❌ FAILED: HTTP #{response.code}"
      return false
    end
  rescue => e
    puts "   ❌ EXCEPTION: #{e.class}: #{e.message}"
    return false
  end
end

# Method 3: Open-URI basic
def test_open_uri_basic(url, output_file)
  puts "\n3️⃣ Testing open-uri basic..."
  
  begin
    URI.open(url) do |file|
      puts "   Content-Type: #{file.content_type}"
      puts "   Status: #{file.status.join(' ')}" if file.respond_to?(:status)
      
      File.open(output_file, 'wb') { |f| f.write(file.read) }
      puts "   ✅ SUCCESS: #{File.size(output_file)} bytes written"
      return true
    end
  rescue => e
    puts "   ❌ EXCEPTION: #{e.class}: #{e.message}"
    return false
  end
end

# Method 4: Open-URI with headers
def test_open_uri_headers(url, output_file)
  puts "\n4️⃣ Testing open-uri with headers..."
  
  options = {
    'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
    'Accept' => 'image/webp,image/apng,image/*,*/*;q=0.8',
    'Accept-Language' => 'en-US,en;q=0.9',
    'Accept-Encoding' => 'gzip, deflate, br',
    'Connection' => 'keep-alive',
    'Referer' => 'https://drive.google.com/'
  }
  
  begin
    URI.open(url, options) do |file|
      puts "   Content-Type: #{file.content_type}"
      puts "   Status: #{file.status.join(' ')}" if file.respond_to?(:status)
      
      File.open(output_file, 'wb') { |f| f.write(file.read) }
      puts "   ✅ SUCCESS: #{File.size(output_file)} bytes written"
      return true
    end
  rescue => e
    puts "   ❌ EXCEPTION: #{e.class}: #{e.message}"
    return false
  end
end

# Method 5: Net::HTTP with SSL options
def test_net_http_ssl(url, output_file)
  puts "\n5️⃣ Testing Net::HTTP with SSL options..."
  
  uri = URI.parse(url)
  
  begin
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # Less strict
    http.ssl_timeout = 30
    http.read_timeout = 30
    http.open_timeout = 30
    
    request = Net::HTTP::Get.new(uri.path)
    request['User-Agent'] = 'curl/7.68.0'  # Try curl user agent
    
    response = http.request(request)
    puts "   Response code: #{response.code}"
    puts "   Content-Type: #{response['content-type']}"
    
    if response.code == '200'
      File.open(output_file, 'wb') { |f| f.write(response.body) }
      puts "   ✅ SUCCESS: #{File.size(output_file)} bytes written"
      return true
    else
      puts "   ❌ FAILED: HTTP #{response.code}"
      return false
    end
  rescue => e
    puts "   ❌ EXCEPTION: #{e.class}: #{e.message}"
    return false
  end
end

# Method 6: HTTParty (if available)
def test_httparty(url, output_file)
  puts "\n6️⃣ Testing HTTParty (if available)..."
  
  begin
    require 'httparty'
    
    response = HTTParty.get(url, {
      headers: {
        'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Accept' => 'image/webp,image/apng,image/*,*/*;q=0.8'
      },
      timeout: 30
    })
    
    puts "   Response code: #{response.code}"
    puts "   Content-Type: #{response.headers['content-type']}"
    
    if response.code == 200
      File.open(output_file, 'wb') { |f| f.write(response.body) }
      puts "   ✅ SUCCESS: #{File.size(output_file)} bytes written"
      return true
    else
      puts "   ❌ FAILED: HTTP #{response.code}"
      return false
    end
  rescue LoadError
    puts "   ⚠️  HTTParty not available"
    return false
  rescue => e
    puts "   ❌ EXCEPTION: #{e.class}: #{e.message}"
    return false
  end
end

# Method 7: System curl (baseline)
def test_system_curl(url, output_file)
  puts "\n7️⃣ Testing system curl (baseline)..."
  
  success = system(
    'curl', '-L', '-s', '-S',
    '-H', 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
    '-H', 'Accept: image/webp,image/apng,image/*,*/*;q=0.8',
    '-o', output_file,
    url
  )
  
  if success && File.exist?(output_file) && File.size(output_file) > 0
    puts "   ✅ SUCCESS: #{File.size(output_file)} bytes written"
    return true
  else
    puts "   ❌ FAILED: curl command failed or empty file"
    return false
  end
end

# Run all tests
methods = [
  [:test_net_http_basic, 'method1_basic.png'],
  [:test_net_http_headers, 'method2_headers.png'],
  [:test_open_uri_basic, 'method3_openuri.png'],
  [:test_open_uri_headers, 'method4_openuri_headers.png'],
  [:test_net_http_ssl, 'method5_ssl.png'],
  [:test_httparty, 'method6_httparty.png'],
  [:test_system_curl, 'method7_curl.png']
]

successful_methods = []

methods.each do |method_name, filename|
  output_path = File.join(OUTPUT_DIR, filename)
  File.delete(output_path) if File.exist?(output_path)
  
  success = send(method_name, URL, output_path)
  successful_methods << method_name if success
end

puts "\n" + "=" * 80
puts "🎯 SUMMARY:"
puts "Successful methods: #{successful_methods.length}/#{methods.length}"
successful_methods.each { |method| puts "   ✅ #{method}" }

if successful_methods.empty?
  puts "❌ All methods failed!"
else
  puts "\n🔍 File sizes:"
  methods.each do |_, filename|
    output_path = File.join(OUTPUT_DIR, filename)
    if File.exist?(output_path)
      size = File.size(output_path)
      puts "   #{filename}: #{size} bytes"
    end
  end
end
