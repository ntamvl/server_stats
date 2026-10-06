# frozen_string_literal: true

require "json"
require_relative "server_stats/version"
require_relative "server_stats/formatter"
require_relative "server_stats/models"
require_relative "server_stats/collector"

module ServerStats
  class << self
    def collector
      @collector ||= Collector.new
    end

    def collector=(custom_collector)
      @collector = custom_collector
    end

    def cpu(interval: 0.5)
      collector.cpu(interval: interval)
    end

    def memory
      collector.memory
    end

    alias ram memory

    def disk(path = "/")
      path = path[:path] if path.is_a?(Hash) && path.key?(:path)
      collector.disk(path)
    end

    def system
      collector.system
    end

    def all(path: "/", interval: 0.5)
      collector.all(path: path, interval: interval)
    end

    alias snapshot all

    def to_h(path: "/", interval: 0.5)
      all(path: path, interval: interval).to_h
    end

    def to_json(path: "/", interval: 0.5, pretty: false)
      hash = to_h(path: path, interval: interval)
      pretty ? JSON.pretty_generate(hash) : hash.to_json
    end

    def summary(path: "/", interval: 0.5)
      snap = all(path: path, interval: interval)
      sys  = snap.system
      cpu  = snap.cpu
      mem  = snap.memory
      dsk  = snap.disk

      load_str = if cpu.load_average.any?
                   "#{cpu.load_average[:one_minute]} (1m), #{cpu.load_average[:five_minutes]} (5m), #{cpu.load_average[:fifteen_minutes]} (15m)"
                 else
                   "N/A"
                 end

      lines = []
      lines << "=" * 60
      lines << "                  SERVER STATS REPORT"
      lines << "=" * 60
      if sys
        lines << format("  %-14s %s %s (%s)", "OS:", sys.os, sys.os_version, sys.architecture)
        lines << format("  %-14s %s", "Hostname:", sys.hostname)
        lines << format("  %-14s %s (Kernel: %s)", "Uptime:", sys.uptime_human, sys.kernel)
        lines << "-" * 60
      end
      if cpu
        lines << format("  %-14s %d cores (Physical: %d)", "CPU Cores:", cpu.cores, cpu.physical_cores)
        lines << format("  %-14s %s", "CPU Model:", cpu.model || "Unknown") if cpu.model
        lines << format("  %-14s %s", "CPU Usage:", Formatter.format_percent(cpu.usage_percent))
        lines << format("  %-14s %s", "Load Avg:", load_str)
        lines << "-" * 60
      end
      if mem
        lines << format("  %-14s %s", "RAM Total:", mem.total_human)
        lines << format("  %-14s %s (%s)", "RAM Used:", mem.used_human, Formatter.format_percent(mem.usage_percent))
        lines << format("  %-14s %s", "RAM Available:", mem.available_human)
        lines << format("  %-14s %s", "RAM Free:", mem.free_human)
        lines << "-" * 60
      end
      if dsk
        lines << format("  %-14s %s (Mount: %s)", "Disk Total:", dsk.total_human, dsk.path)
        lines << format("  %-14s %s (%s)", "Disk Used:", dsk.used_human, Formatter.format_percent(dsk.usage_percent))
        lines << format("  %-14s %s", "Disk Available:", dsk.available_human)
        lines << format("  %-14s %s", "Filesystem:", dsk.filesystem)
      end
      lines << "=" * 60
      lines.join("\n")
    end
  end
end
