# frozen_string_literal: true

require 'date'

# Date validation and formatting utilities
module DateValidator
  # Check if date string is valid ISO format (YYYY-MM-DD)
  def valid_date?(date_string)
    return false unless date_string.is_a?(String)
    return false unless date_string.match?(/^\d{4}-\d{2}-\d{2}$/)
    
    # Parse and validate the date
    year, month, day = date_string.split('-').map(&:to_i)
    return false if month < 1 || month > 12
    return false if day < 1 || day > 31
    
    # Check for valid month/day combinations
    case month
    when 2
      leap_year = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
      return false if day > (leap_year ? 29 : 28)
    when 4, 6, 9, 11
      return false if day > 30
    end
    
    true
  rescue
    false
  end
  
  # Parse date string and return ISO format (YYYY-MM-DD)
  def parse_date(date_string, output_format: '%Y-%m-%d')
    return nil if date_string.nil? || date_string.to_s.strip.empty?
    
    begin
      # Try parsing as ISO date first
      if date_string.match?(/^\d{4}-\d{2}-\d{2}/)
        date = Date.parse(date_string)
        return date.strftime(output_format)
      end
      
      # Try parsing other formats
      date = Date.parse(date_string)
      date.strftime(output_format)
    rescue ArgumentError, TypeError
      nil
    end
  end
  
  # Format date string or Date object
  def format_date(date_input, format = '%Y-%m-%d')
    return nil if date_input.nil?
    return '' if date_input.to_s.strip.empty?
    
    begin
      if date_input.is_a?(Date)
        date_input.strftime(format)
      elsif date_input.respond_to?(:strftime)
        date_input.strftime(format)
      elsif date_input.is_a?(String)
        parsed = Date.parse(date_input)
        parsed.strftime(format)
      else
        date_input.to_s
      end
    rescue ArgumentError, TypeError
      date_input.to_s
    end
  end
  
  # Check if date string is in ISO format
  def iso_date?(date_string)
    return false if date_string.nil? || date_string.to_s.strip.empty?
    date_string.match?(/^\d{4}-\d{2}-\d{2}$/)
  end
  
  # Check if date is within a range
  def date_in_range?(date_string, start_date, end_date)
    return false unless valid_date?(date_string)
    return false unless valid_date?(start_date)
    return false unless valid_date?(end_date)
    
    begin
      date = Date.parse(date_string)
      range_start = Date.parse(start_date)
      range_end = Date.parse(end_date)
      
      date >= range_start && date <= range_end
    rescue ArgumentError
      false
    end
  end
  
  # Compare two dates (-1 if date1 < date2, 0 if equal, 1 if date1 > date2)
  def compare_dates(date1, date2)
    return nil unless valid_date?(date1) && valid_date?(date2)
    
    begin
      d1 = Date.parse(date1)
      d2 = Date.parse(date2)
      d1 <=> d2
    rescue ArgumentError
      nil
    end
  end
end
