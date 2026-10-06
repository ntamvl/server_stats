# frozen_string_literal: true

require_relative "test_helper"

class MacOsProviderTest
  include TestRunner

  def run
    puts "\nRunning MacOsProviderTest..."

    provider = ServerStats::Providers::MacOs.new

    # Test vm_stat parser
    sample_vm_stat = <<~VMSTAT
      Mach Virtual Memory Statistics: (page size of 16384 bytes)
      Pages free:                                 10000.
      Pages active:                               50000.
      Pages inactive:                             20000.
      Pages speculative:                           1000.
      Pages throttled:                                0.
      Pages wired down:                           15000.
      Pages purgeable:                              500.
      Pages stored in compressor:                  5000.
      Pages occupied by compressor:                2000.
    VMSTAT

    stats, page_size = provider.parse_vm_stat(sample_vm_stat)
    assert_equal 16384, page_size
    assert_equal 10000, stats["Pages free"]
    assert_equal 20000, stats["Pages inactive"]
    assert_equal 1000, stats["Pages speculative"]
    assert_equal 500, stats["Pages purgeable"]

    # Test iostat parser
    sample_iostat = <<~IOSTAT
                    disk0       cpu    load average
          KB/t  tps  MB/s  us sy id   1m   5m   15m
         40.97 1161 46.46   6  4 90  2.87 3.33 3.42
         26.15   39  0.99  12  8 80  2.87 3.33 3.42
    IOSTAT

    usage = provider.parse_iostat_cpu(sample_iostat)
    assert_equal 20.0, usage

    # If running on macOS, test live collection methods
    if ServerStats::OS.macos?
      mem = provider.memory
      assert mem.total_bytes > 0, "macOS memory total should be > 0"
      assert mem.available_bytes > 0, "macOS memory available should be > 0"
      assert mem.usage_percent >= 0.0 && mem.usage_percent <= 100.0

      sys = provider.system
      assert_equal :macos, sys.os_family
      assert_match(/macOS/i, sys.os)
      assert sys.uptime_seconds > 0

      cpu = provider.cpu(0.2)
      assert cpu.cores > 0
      assert cpu.usage_percent >= 0.0 && cpu.usage_percent <= 100.0

      disk = provider.disk("/")
      assert disk.total_bytes > 0
      assert disk.available_bytes > 0
    end
  end
end
