# frozen_string_literal: true

require "open3"
require "socket"
require "etc"
require "shellwords"
require_relative "../models"

module ServerStats
  module Providers
    class Base
      # Execute command safely without raising exception
      def execute(command)
        stdout, _stderr, status = Open3.capture3(command)
        return stdout.strip if status.success?

        ""
      rescue StandardError
        ""
      end

      # Cross-platform disk stats using POSIX `df -P -k <path>`
      def disk_stats(path = "/")
        clean_path = path.to_s.strip
        clean_path = "/" if clean_path.empty?

        output = execute("df -P -k #{clean_path.shellescape}")
        lines = output.lines.map(&:strip).reject(&:empty?)

        if lines.size >= 2
          # Skip header line, parse first data line
          parts = lines[1].split(/\s+/)
          filesystem = parts[0]
          total_kb = parts[1].to_i
          used_kb = parts[2].to_i
          available_kb = parts[3].to_i

          total_bytes = total_kb * 1024
          used_bytes = used_kb * 1024
          available_bytes = available_kb * 1024

          DiskStats.new(
            path: clean_path,
            filesystem: filesystem,
            total_bytes: total_bytes,
            used_bytes: used_bytes,
            available_bytes: available_bytes,
            free_bytes: available_bytes
          )
        else
          DiskStats.new(
            path: clean_path,
            filesystem: "unknown",
            total_bytes: 0,
            used_bytes: 0,
            available_bytes: 0,
            free_bytes: 0
          )
        end
      end

      # Logical CPU core count via Ruby's standard Etc
      def cpu_cores
        Etc.nprocessors
      rescue StandardError
        1
      end

      # Hostname helper
      def hostname
        Socket.gethostname
      rescue StandardError
        "localhost"
      end

      # Abstract methods to be implemented by OS providers
      def cpu(_interval = 0.5)
        raise NotImplementedError
      end

      def memory
        raise NotImplementedError
      end

      def disk(path = "/")
        disk_stats(path)
      end

      def system
        raise NotImplementedError
      end
    end
  end
end
