# frozen_string_literal: true

require_relative "test_helper"

class FormatterTest
  include TestRunner

  def run
    puts "\nRunning FormatterTest..."

    # Bytes to human
    assert_equal "0 B", ServerStats::Formatter.bytes_to_human(0)
    assert_equal "500 B", ServerStats::Formatter.bytes_to_human(500)
    assert_equal "1.00 KB", ServerStats::Formatter.bytes_to_human(1024)
    assert_equal "1.50 KB", ServerStats::Formatter.bytes_to_human(1536)
    assert_equal "1.00 MB", ServerStats::Formatter.bytes_to_human(1024 * 1024)
    assert_equal "1.00 GB", ServerStats::Formatter.bytes_to_human(1024 * 1024 * 1024)
    assert_equal "2.50 TB", ServerStats::Formatter.bytes_to_human((2.5 * 1024 * 1024 * 1024 * 1024).to_i)

    # Seconds to human
    assert_equal "0s", ServerStats::Formatter.seconds_to_human(0)
    assert_equal "45s", ServerStats::Formatter.seconds_to_human(45)
    assert_equal "2m 30s", ServerStats::Formatter.seconds_to_human(150)
    assert_equal "1h 15m", ServerStats::Formatter.seconds_to_human(4500)
    assert_equal "2d 3h 4m 5s", ServerStats::Formatter.seconds_to_human(2 * 86_400 + 3 * 3600 + 4 * 60 + 5)

    # Format percentage
    assert_equal "0.00%", ServerStats::Formatter.format_percent(0)
    assert_equal "15.42%", ServerStats::Formatter.format_percent(15.424)
    assert_equal "100.00%", ServerStats::Formatter.format_percent(100.0)
  end
end
