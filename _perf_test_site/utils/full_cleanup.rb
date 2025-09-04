#!/usr/bin/env ruby

require 'fileutils'

class FullCleanup
  def initialize(auto_confirm: false)
    @root_dir = File.expand_path('..', __dir__)
    @auto_confirm = auto_confirm
    @errors = []
    puts "🧹 Full Cleanup Script"
    puts "Working directory: #{@root_dir}"
    puts
  end

  def run
    confirm_cleanup unless @auto_confirm
    
    puts "\n🗂️  Step 1: Cleaning up talks..."
    cleanup_talks
    
    puts "\n📄 Step 2: Cleaning up PDFs..."
    cleanup_pdfs
    
    puts "\n🖼️  Step 3: Cleaning up thumbnails..."
    cleanup_thumbnails
    
    puts "\n☁️  Step 4: Running Google Drive cleanup..."
    cleanup_google_drive
    
    puts "\n" + "="*50
    if @errors.empty?
      puts "🎉 Full cleanup complete!"
      puts "All generated content has been removed successfully."
    else
      puts "⚠️  Cleanup completed with #{@errors.length} error(s):"
      @errors.each { |error| puts "   • #{error}" }
      puts "\nLocal files were cleaned up successfully."
    end
  end

  private

  def confirm_cleanup
    puts "⚠️  WARNING: This will DELETE ALL of the following:"
    puts "   • All talk files in _talks/"
    puts "   • All PDF files in pdfs/"
    puts "   • All thumbnail images in assets/images/thumbnails/"
    puts "   • All files in Google Drive migration folder"
    puts
    print "Are you sure you want to continue? (y/N): "
    
    response = STDIN.gets.chomp.downcase
    unless ['y', 'yes'].include?(response)
      puts "Cleanup cancelled."
      exit 0
    end
    puts
  end

  def cleanup_talks
    talks_dir = File.join(@root_dir, '_talks')
    
    if Dir.exist?(talks_dir)
      talk_files = Dir.glob(File.join(talks_dir, '*.md'))
      
      if talk_files.empty?
        puts "   No talk files found to delete"
      else
        puts "   Found #{talk_files.length} talk files to delete:"
        talk_files.each do |file|
          filename = File.basename(file)
          puts "   • #{filename}"
          File.delete(file)
        end
        puts "   ✅ Deleted #{talk_files.length} talk files"
      end
    else
      puts "   _talks directory does not exist"
    end
  end

  def cleanup_pdfs
    pdfs_dir = File.join(@root_dir, 'pdfs')
    
    if Dir.exist?(pdfs_dir)
      pdf_files = Dir.glob(File.join(pdfs_dir, '*.pdf'))
      
      if pdf_files.empty?
        puts "   No PDF files found to delete"
      else
        puts "   Found #{pdf_files.length} PDF files to delete:"
        pdf_files.each do |file|
          filename = File.basename(file)
          puts "   • #{filename}"
          File.delete(file)
        end
        puts "   ✅ Deleted #{pdf_files.length} PDF files"
      end
    else
      puts "   pdfs directory does not exist"
    end
  end

  def cleanup_thumbnails
    thumbnails_dir = File.join(@root_dir, 'assets', 'images', 'thumbnails')
    
    if Dir.exist?(thumbnails_dir)
      thumbnail_files = Dir.glob(File.join(thumbnails_dir, '*'))
      
      if thumbnail_files.empty?
        puts "   No thumbnail files found to delete"
      else
        puts "   Found #{thumbnail_files.length} thumbnail files to delete:"
        thumbnail_files.each do |file|
          filename = File.basename(file)
          puts "   • #{filename}"
          if File.file?(file)
            File.delete(file)
          elsif File.directory?(file)
            FileUtils.rm_rf(file)
          end
        end
        puts "   ✅ Deleted #{thumbnail_files.length} thumbnail files"
      end
    else
      puts "   assets/images/thumbnails directory does not exist"
    end
  end

  def cleanup_google_drive
    google_drive_script = File.join(@root_dir, 'utils', 'google_drive', 'cleanup_google_drive.rb')
    
    if File.exist?(google_drive_script)
      puts "   Running Google Drive cleanup script..."
      
      # Change to root directory to ensure proper paths and use bundle exec
      Dir.chdir(@root_dir) do
        system("bundle exec ruby #{google_drive_script}")
      end
      
      if $?.success?
        puts "   ✅ Google Drive cleanup completed"
      else
        error_msg = "Google Drive cleanup script failed (check API credentials or network)"
        puts "   ❌ #{error_msg}"
        @errors << error_msg
      end
    else
      error_msg = "Google Drive cleanup script not found"
      puts "   ❌ #{error_msg}"
      @errors << error_msg
    end
  end
end

# Run the cleanup if this script is executed directly
if __FILE__ == $0
  auto_confirm = ARGV.include?('--yes') || ARGV.include?('-y')
  FullCleanup.new(auto_confirm: auto_confirm).run
end
