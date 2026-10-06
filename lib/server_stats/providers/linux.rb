# frozen_string_literal: true

require_relative "base"

module ServerStats
  module Providers
    class Linux < Base
      attr_accessor :proc_meminfo_path, :proc_stat_path, :proc_loadavg_path,
                    :proc_uptime_path, :proc_cpuinfo_path, :os_release_path

      def initialize(options = {})
        super()
        @proc_meminfo_path = options[:proc_meminfo_path] || "/proc/meminfo"
        @proc_stat_path    = options[:proc_stat_path]    || "/proc/stat"
        @proc_loadavg_path = options[:proc_loadavg_path] || "/proc/loadavg"
        @proc_uptime_path  = options[:proc_uptime_path]  || "/proc/uptime"
        @proc_cpuinfo_path = options[:proc_cpuinfo_path] || "/proc/cpuinfo"
        @os_release_path   = options[:os_release_path]   || "/etc/os-release"
      end

      # Collect CPU statistics on Linux
      def cpu(interval = 0.5)
        cores = cpu_cores
        model, physical_cores = parse_cpuinfo
        load_avg = parse_load_average
        usage_pct = calculate_cpu_usage(interval.to_f)

        CpuStats.new(
          cores: cores,
          physical_cores: physical_cores || cores,
          usage_percent: usage_pct,
          load_average: load_avg,
          model: model
        )
      end

      # Collect Memory statistics on Linux
      def memory
        meminfo = parse_meminfo

        total_bytes     = (meminfo["MemTotal"] || 0) * 1024
        free_bytes      = (meminfo["MemFree"] || 0) * 1024
        buffers_bytes   = (meminfo["Buffers"] || 0) * 1024
        cached_bytes    = (meminfo["Cached"] || 0) * 1024
        available_kb    = meminfo["MemAvailable"]

        available_bytes = if available_kb
                            available_kb * 1024
                          else
                            free_bytes + buffers_bytes + cached_bytes
                          end

        used_bytes = [total_bytes - available_bytes, 0].max

        MemoryStats.new(
          total_bytes: total_bytes,
          free_bytes: free_bytes,
          available_bytes: available_bytes,
          used_bytes: used_bytes,
          details: {
            buffers_bytes: buffers_bytes,
            cached_bytes: cached_bytes,
            swap_total_bytes: (meminfo["SwapTotal"] || 0) * 1024,
            swap_free_bytes: (meminfo["SwapFree"] || 0) * 1024
          }
        )
      end

      # Collect System statistics on Linux
      def system
        os_name, os_ver = parse_os_release
        arch = execute("uname -m")
        arch = "unknown" if arch.empty?

        kernel = execute("uname -r")
        kernel = "unknown" if kernel.empty?

        uptime_secs = parse_uptime

        SystemStats.new(
          os: os_name,
          os_family: :linux,
          os_version: os_ver,
          hostname: hostname,
          architecture: arch,
          kernel: kernel,
          uptime_seconds: uptime_secs
        )
      end

      # Internal helper: parse /proc/meminfo
      def parse_meminfo
        return {} unless File.exist?(@proc_meminfo_path)

        info = {}
        File.foreach(@proc_meminfo_path) do |line|
          if (m = line.match(/^(\w+):\s+(\d+)\s+kB/))
            info[m[1]] = m[2].to_i
          end
        end
        info
      rescue StandardError
        {}
      end

      # Internal helper: parse /proc/loadavg
      def parse_load_average
        return { one_minute: 0.0, five_minutes: 0.0, fifteen_minutes: 0.0 } unless File.exist?(@proc_loadavg_path)

        parts = File.read(@proc_loadavg_path).strip.split(/\s+/)
        {
          one_minute: parts[0].to_f,
          five_minutes: parts[1].to_f,
          fifteen_minutes: parts[2].to_f
        }
      rescue StandardError
        { one_minute: 0.0, five_minutes: 0.0, fifteen_minutes: 0.0 }
      end

      # Internal helper: parse /proc/uptime
      def parse_uptime
        return 0 unless File.exist?(@proc_uptime_path)

        parts = File.read(@proc_uptime_path).strip.split(/\s+/)
        parts[0].to_f.to_i
      rescue StandardError
        0
      end

      # Internal helper: parse /proc/cpuinfo
      def parse_cpuinfo
        return [nil, nil] unless File.exist?(@proc_cpuinfo_path)

        model = nil
        physical_core_pairs = {}
        current_phys_id = nil

        File.foreach(@proc_cpuinfo_path) do |line|
          line = line.strip
          if line.start_with?("model name")
            model ||= line.split(":", 2)[1]&.strip
          elsif line.start_with?("physical id")
            current_phys_id = line.split(":", 2)[1]&.strip
          elsif line.start_with?("core id") && current_phys_id
            core_id = line.split(":", 2)[1]&.strip
            physical_core_pairs["#{current_phys_id}-#{core_id}"] = true
          end
        end

        phys_count = physical_core_pairs.empty? ? nil : physical_core_pairs.size
        [model, phys_count]
      rescue StandardError
        [nil, nil]
      end

      # Internal helper: read first CPU line from /proc/stat
      def read_cpu_ticks
        return nil unless File.exist?(@proc_stat_path)

        File.foreach(@proc_stat_path) do |line|
          if line.start_with?("cpu ")
            # cpu  user nice system idle iowait irq softirq steal guest guest_nice
            fields = line.strip.split(/\s+/)[1..-1].map(&:to_i)
            idle = (fields[3] || 0) + (fields[4] || 0) # idle + iowait
            total = fields.inject(0, :+)
            return { idle: idle, total: total }
          end
        end
        nil
      rescue StandardError
        nil
      end

      # Internal helper: calculate CPU % using sample interval
      def calculate_cpu_usage(interval)
        sample1 = read_cpu_ticks
        return 0.0 unless sample1

        if interval > 0.0
          sleep(interval)
          sample2 = read_cpu_ticks
          return 0.0 unless sample2

          delta_total = sample2[:total] - sample1[:total]
          delta_idle  = sample2[:idle] - sample1[:idle]

          if delta_total.positive?
            usage = ((delta_total - delta_idle).to_f / delta_total) * 100.0
            return [[usage, 0.0].max, 100.0].min
          end
        end

        0.0
      end

      # Internal helper: parse /etc/os-release
      def parse_os_release
        return ["Linux", "unknown"] unless File.exist?(@os_release_path)

        env = {}
        File.foreach(@os_release_path) do |line|
          line = line.strip
          next if line.empty? || line.start_with?("#")

          if (m = line.match(/^([A-Za-z_]+)=(?:"([^"]*)"|'([^']*)'|(.*))$/))
            key = m[1]
            val = m[2] || m[3] || m[4]
            env[key] = val
          end
        end

        name = env["PRETTY_NAME"] || env["NAME"] || "Linux"
        version = env["VERSION_ID"] || env["VERSION"] || "unknown"
        [name, version]
      rescue StandardError
        ["Linux", "unknown"]
      end
    end
  end
end
