# frozen_string_literal: true

require_relative "base"

module ServerStats
  module Providers
    class MacOs < Base
      attr_accessor :sysctl_executor, :vm_stat_output, :iostat_output

      def initialize(options = {})
        super()
        @options = options
      end

      # Collect CPU statistics on macOS
      def cpu(interval = 0.5)
        cores = logical_cpu_cores
        phys_cores = physical_cpu_cores
        model = cpu_model
        load_avg = parse_load_average
        usage_pct = calculate_cpu_usage(interval.to_f)

        CpuStats.new(
          cores: cores,
          physical_cores: phys_cores || cores,
          usage_percent: usage_pct,
          load_average: load_avg,
          model: model
        )
      end

      # Collect Memory statistics on macOS
      def memory
        total_bytes = sysctl_int("hw.memsize")
        vm_output = @vm_stat_output || execute("vm_stat")
        stats, page_size = parse_vm_stat(vm_output)

        free_pages        = stats["Pages free"] || 0
        speculative_pages = stats["Pages speculative"] || 0
        inactive_pages    = stats["Pages inactive"] || 0
        purgeable_pages   = stats["Pages purgeable"] || 0
        wired_pages       = stats["Pages wired down"] || 0
        active_pages      = stats["Pages active"] || 0
        compressor_pages  = stats["Pages occupied by compressor"] || 0

        free_bytes      = (free_pages + speculative_pages) * page_size
        available_bytes = (free_pages + inactive_pages + speculative_pages + purgeable_pages) * page_size
        available_bytes = [available_bytes, total_bytes].min
        used_bytes      = [total_bytes - available_bytes, 0].max

        MemoryStats.new(
          total_bytes: total_bytes,
          free_bytes: free_bytes,
          available_bytes: available_bytes,
          used_bytes: used_bytes,
          details: {
            page_size_bytes: page_size,
            active_bytes: active_pages * page_size,
            inactive_bytes: inactive_pages * page_size,
            wired_bytes: wired_pages * page_size,
            purgeable_bytes: purgeable_pages * page_size,
            compressed_bytes: compressor_pages * page_size
          }
        )
      end

      # Collect System statistics on macOS
      def system
        product_name = execute("sw_vers -productName")
        product_name = "macOS" if product_name.empty?

        version = execute("sw_vers -productVersion")
        version = "unknown" if version.empty?

        arch = execute("uname -m")
        arch = "unknown" if arch.empty?

        kernel = execute("uname -r")
        kernel = "unknown" if kernel.empty?

        uptime_secs = parse_uptime

        SystemStats.new(
          os: product_name,
          os_family: :macos,
          os_version: version,
          hostname: hostname,
          architecture: arch,
          kernel: kernel,
          uptime_seconds: uptime_secs
        )
      end

      # Internal helper: logical CPU cores
      def logical_cpu_cores
        val = sysctl_int("hw.ncpu")
        val.positive? ? val : cpu_cores
      end

      # Internal helper: physical CPU cores
      def physical_cpu_cores
        val = sysctl_int("hw.physicalcpu")
        val.positive? ? val : logical_cpu_cores
      end

      # Internal helper: CPU model brand string
      def cpu_model
        brand = execute("sysctl -n machdep.cpu.brand_string")
        return brand unless brand.empty?

        model = execute("sysctl -n hw.model")
        return model unless model.empty?

        nil
      end

      # Internal helper: sysctl integer helper
      def sysctl_int(key)
        execute("sysctl -n #{key}").to_i
      end

      # Internal helper: parse load average on macOS
      def parse_load_average
        raw = execute("sysctl -n vm.loadavg")
        if (m = raw.match(/\{\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)\s*\}/))
          return {
            one_minute: m[1].to_f,
            five_minutes: m[2].to_f,
            fifteen_minutes: m[3].to_f
          }
        end

        # Fallback to uptime command
        uptime_str = execute("uptime")
        if (m = uptime_str.match(/load averages?:\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)/))
          return {
            one_minute: m[1].to_f,
            five_minutes: m[2].to_f,
            fifteen_minutes: m[3].to_f
          }
        end

        { one_minute: 0.0, five_minutes: 0.0, fifteen_minutes: 0.0 }
      rescue StandardError
        { one_minute: 0.0, five_minutes: 0.0, fifteen_minutes: 0.0 }
      end

      # Internal helper: parse vm_stat output
      def parse_vm_stat(output)
        return [{}, 4096] if output.nil? || output.empty?

        page_size = output[/page size of (\d+) bytes/, 1]&.to_i || 4096
        stats = {}

        output.each_line do |line|
          if (m = line.match(/^"?([^":]+)"?:\s+(\d+)\./))
            stats[m[1].strip] = m[2].to_i
          end
        end

        [stats, page_size]
      rescue StandardError
        [{}, 4096]
      end

      # Internal helper: parse uptime on macOS
      def parse_uptime
        raw = execute("sysctl -n kern.boottime")
        if (m = raw.match(/sec\s*=\s*(\d+)/))
          boot_time = m[1].to_i
          return [Time.now.to_i - boot_time, 0].max
        end

        0
      rescue StandardError
        0
      end

      # Internal helper: calculate CPU usage % on macOS
      def calculate_cpu_usage(interval)
        # Attempt 1: iostat with wait interval
        sample_sec = [interval.round, 1].max
        out = @iostat_output || execute("iostat -c 2 -w #{sample_sec}")
        if (pct = parse_iostat_cpu(out))
          return pct
        end

        # Attempt 2: top snapshot
        top_out = execute("top -l 1 -n 0")
        if (m = top_out.match(/CPU usage:\s*([\d.]+)%\s*user,\s*([\d.]+)%\s*sys/))
          return (m[1].to_f + m[2].to_f).round(2)
        end

        0.0
      rescue StandardError
        0.0
      end

      # Parse iostat output for CPU utilization
      def parse_iostat_cpu(output)
        return nil if output.nil? || output.empty?

        lines = output.lines.map(&:strip).reject(&:empty?)
        return nil if lines.size < 2

        # The last line has the second sample interval stats
        last_parts = lines.last.split(/\s+/)
        header_line = lines.find { |l| l.include?("us") && l.include?("sy") && l.include?("id") }
        return nil unless header_line

        # In iostat output: ... us sy id 1m 5m 15m
        # Counting from end: -6 is us, -5 is sy, -4 is id
        if last_parts.size >= 6
          id = last_parts[-4].to_f
          usage = 100.0 - id
          return [[usage, 0.0].max, 100.0].min.round(2)
        end

        nil
      rescue StandardError
        nil
      end
    end
  end
end
