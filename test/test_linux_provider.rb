# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

class LinuxProviderTest
  include TestRunner

  def run
    puts "\nRunning LinuxProviderTest..."

    Dir.mktmpdir do |dir|
      meminfo_file = File.join(dir, "meminfo")
      File.write(meminfo_file, <<~MEMINFO)
        MemTotal:       16384000 kB
        MemFree:         2048000 kB
        MemAvailable:   10240000 kB
        Buffers:          512000 kB
        Cached:          7680000 kB
        SwapTotal:       4096000 kB
        SwapFree:        4096000 kB
      MEMINFO

      stat_file = File.join(dir, "stat")
      File.write(stat_file, "cpu  1000 200 300 8000 500 10 20 0 0 0\n")

      loadavg_file = File.join(dir, "loadavg")
      File.write(loadavg_file, "0.75 1.25 1.50 2/250 12345\n")

      uptime_file = File.join(dir, "uptime")
      File.write(uptime_file, "7200.50 14400.20\n")

      cpuinfo_file = File.join(dir, "cpuinfo")
      File.write(cpuinfo_file, <<~CPUINFO)
        processor	: 0
        model name	: AMD EPYC 7763 64-Core Processor
        physical id	: 0
        core id		: 0

        processor	: 1
        model name	: AMD EPYC 7763 64-Core Processor
        physical id	: 0
        core id		: 1
      CPUINFO

      os_release_file = File.join(dir, "os-release")
      File.write(os_release_file, <<~OSREL)
        NAME="Ubuntu"
        VERSION="22.04.4 LTS (Jammy Jellyfish)"
        ID=ubuntu
        PRETTY_NAME="Ubuntu 22.04.4 LTS"
        VERSION_ID="22.04"
      OSREL

      provider = ServerStats::Providers::Linux.new(
        proc_meminfo_path: meminfo_file,
        proc_stat_path: stat_file,
        proc_loadavg_path: loadavg_file,
        proc_uptime_path: uptime_file,
        proc_cpuinfo_path: cpuinfo_file,
        os_release_path: os_release_file
      )

      # Test memory parsing
      mem = provider.memory
      assert_equal 16_384_000 * 1024, mem.total_bytes
      assert_equal 10_240_000 * 1024, mem.available_bytes
      assert_equal 2_048_000 * 1024, mem.free_bytes
      assert_equal (16_384_000 - 10_240_000) * 1024, mem.used_bytes
      assert_in_delta 37.5, mem.usage_percent, 0.1

      # Test cpu parsing
      cpu = provider.cpu(0)
      assert_equal "AMD EPYC 7763 64-Core Processor", cpu.model
      assert_equal 2, cpu.physical_cores
      assert_equal 0.75, cpu.load_average[:one_minute]
      assert_equal 1.25, cpu.load_average[:five_minutes]
      assert_equal 1.50, cpu.load_average[:fifteen_minutes]

      # Test system parsing
      sys = provider.system
      assert_equal "Ubuntu 22.04.4 LTS", sys.os
      assert_equal :linux, sys.os_family
      assert_equal "22.04", sys.os_version
      assert_equal 7200, sys.uptime_seconds
      assert_equal "2h", sys.uptime_human
    end
  end
end
