# frozen_string_literal: true

require 'minitest/autorun'
require 'date'
require_relative '../../lib/utils/date_validator'

class DateValidatorTest < Minitest::Test
  include DateValidator
  
  # Test valid_date? method
  
  def test_valid_date_with_correct_format
    assert valid_date?('2024-12-04')
    assert valid_date?('2025-01-15')
    assert valid_date?('2023-06-30')
  end
  
  def test_valid_date_with_leap_year
    assert valid_date?('2024-02-29')  # 2024 is a leap year
    assert valid_date?('2020-02-29')  # 2020 is a leap year
  end
  
  def test_invalid_date_with_non_leap_year
    refute valid_date?('2023-02-29')  # 2023 is not a leap year
    refute valid_date?('2025-02-29')  # 2025 is not a leap year
  end
  
  def test_invalid_date_with_wrong_format
    refute valid_date?('12-04-2024')  # Wrong order
    refute valid_date?('2024/12/04')  # Wrong separator
    refute valid_date?('2024-12-4')   # Missing leading zero
    refute valid_date?('24-12-04')    # Two-digit year
  end
  
  def test_invalid_date_with_invalid_month
    refute valid_date?('2024-00-15')  # Month 0
    refute valid_date?('2024-13-15')  # Month 13
    refute valid_date?('2024-99-15')  # Month 99
  end
  
  def test_invalid_date_with_invalid_day
    refute valid_date?('2024-12-00')  # Day 0
    refute valid_date?('2024-12-32')  # Day 32
    refute valid_date?('2024-04-31')  # April has 30 days
    refute valid_date?('2024-06-31')  # June has 30 days
    refute valid_date?('2024-09-31')  # September has 30 days
    refute valid_date?('2024-11-31')  # November has 30 days
  end
  
  def test_invalid_date_with_february_edge_cases
    refute valid_date?('2024-02-30')  # February never has 30 days
    refute valid_date?('2023-02-29')  # Non-leap year
  end
  
  def test_invalid_date_empty_or_nil
    refute valid_date?(nil)
    refute valid_date?('')
    refute valid_date?('   ')
  end
  
  def test_invalid_date_with_non_string
    refute valid_date?(20241204)
    refute valid_date?(Date.today)
  end
  
  # Test parse_date method
  
  def test_parse_date_with_valid_iso_format
    assert_equal '2024-12-04', parse_date('2024-12-04')
    assert_equal '2025-01-15', parse_date('2025-01-15')
  end
  
  def test_parse_date_with_iso_datetime
    assert_equal '2024-12-04', parse_date('2024-12-04T10:30:00Z')
    assert_equal '2025-06-20', parse_date('2025-06-20T08:00:00+02:00')
  end
  
  def test_parse_date_with_various_formats
    assert_equal '2024-12-04', parse_date('December 4, 2024')
    assert_equal '2024-12-04', parse_date('Dec 4, 2024')
    assert_equal '2024-12-04', parse_date('04 Dec 2024')
  end
  
  def test_parse_date_returns_nil_for_invalid
    assert_nil parse_date('not a date')
    assert_nil parse_date('invalid')
    assert_nil parse_date('')
    assert_nil parse_date(nil)
  end
  
  def test_parse_date_with_custom_format
    assert_equal '2024-12-04', parse_date('2024-12-04', output_format: '%Y-%m-%d')
    assert_equal '12/04/2024', parse_date('2024-12-04', output_format: '%m/%d/%Y')
    assert_equal 'December 04, 2024', parse_date('2024-12-04', output_format: '%B %d, %Y')
  end
  
  # Test format_date method
  
  def test_format_date_with_default_format
    assert_equal '2024-12-04', format_date('2024-12-04')
  end
  
  def test_format_date_with_custom_format
    assert_equal 'December 04, 2024', format_date('2024-12-04', '%B %d, %Y')
    assert_equal '12/04/2024', format_date('2024-12-04', '%m/%d/%Y')
    assert_equal 'Dec 2024', format_date('2024-12-04', '%b %Y')
  end
  
  def test_format_date_with_date_object
    date = Date.new(2024, 12, 4)
    assert_equal '2024-12-04', format_date(date)
    assert_equal 'December 04, 2024', format_date(date, '%B %d, %Y')
  end
  
  def test_format_date_returns_original_for_invalid
    assert_equal 'invalid', format_date('invalid')
    assert_equal '', format_date('')
    assert_nil format_date(nil)
  end
  
  # Test iso_date? method
  
  def test_iso_date_with_valid_format
    assert iso_date?('2024-12-04')
    assert iso_date?('2025-01-15')
    assert iso_date?('2023-06-30')
  end
  
  def test_iso_date_with_invalid_format
    refute iso_date?('12-04-2024')
    refute iso_date?('2024/12/04')
    refute iso_date?('December 4, 2024')
  end
  
  def test_iso_date_with_nil_or_empty
    refute iso_date?(nil)
    refute iso_date?('')
  end
  
  # Test date_in_range? method
  
  def test_date_in_range_with_valid_range
    assert date_in_range?('2024-12-04', '2024-01-01', '2024-12-31')
    assert date_in_range?('2024-06-15', '2024-01-01', '2024-12-31')
  end
  
  def test_date_in_range_at_boundaries
    assert date_in_range?('2024-01-01', '2024-01-01', '2024-12-31')
    assert date_in_range?('2024-12-31', '2024-01-01', '2024-12-31')
  end
  
  def test_date_not_in_range
    refute date_in_range?('2023-12-31', '2024-01-01', '2024-12-31')
    refute date_in_range?('2025-01-01', '2024-01-01', '2024-12-31')
  end
  
  def test_date_in_range_with_invalid_dates
    refute date_in_range?('invalid', '2024-01-01', '2024-12-31')
    refute date_in_range?('2024-12-04', 'invalid', '2024-12-31')
    refute date_in_range?('2024-12-04', '2024-01-01', 'invalid')
  end
  
  # Test compare_dates method
  
  def test_compare_dates_equal
    assert_equal 0, compare_dates('2024-12-04', '2024-12-04')
  end
  
  def test_compare_dates_before
    assert_equal(-1, compare_dates('2024-12-03', '2024-12-04'))
    assert_equal(-1, compare_dates('2023-12-04', '2024-12-04'))
  end
  
  def test_compare_dates_after
    assert_equal 1, compare_dates('2024-12-05', '2024-12-04')
    assert_equal 1, compare_dates('2025-12-04', '2024-12-04')
  end
  
  def test_compare_dates_with_invalid
    assert_nil compare_dates('invalid', '2024-12-04')
    assert_nil compare_dates('2024-12-04', 'invalid')
  end
end
