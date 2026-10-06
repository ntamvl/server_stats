# frozen_string_literal: true

module ServerStats
  module Formatter
    UNITS = %w[B KB MB GB TB PB].freeze

    module_function

    # Format bytes to human readable string (e.g. 1073741824 -> "1.00 GB")
    def bytes_to_human(bytes, precision = 2)
      return "0 B" if bytes.nil? || bytes <= 0

      value = bytes.to_f
      unit_index = 0

      while value >= 1024.0 && unit_index < UNITS.size - 1
        value /= 1024.0
        unit_index += 1
      end

      if unit_index.zero?
        "#{bytes} B"
      else
        "#{format("%.#{precision}f", value)} #{UNITS[unit_index]}"
      end
    end

    # Format seconds to human readable string (e.g. 90061 -> "1d 1h 1m 1s")
    def seconds_to_human(total_seconds)
      return "0s" if total_seconds.nil? || total_seconds <= 0

      secs = total_seconds.to_i
      days = secs / 86_400
      hours = (secs % 86_400) / 3600
      minutes = (secs % 3600) / 60
      seconds = secs % 60

      parts = []
      parts << "#{days}d" if days.positive?
      parts << "#{hours}h" if hours.positive?
      parts << "#{minutes}m" if minutes.positive?
      parts << "#{seconds}s" if seconds.positive? || parts.empty?

      parts.join(" ")
    end

    # Format percentage with standard precision
    def format_percent(percent, precision = 2)
      return "0.0%" if percent.nil?

      "#{format("%.#{precision}f", percent)}%"
    end
  end
end
