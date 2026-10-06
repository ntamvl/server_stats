# frozen_string_literal: true

require_relative "test_helper"

class MockProvider < ServerStats::Providers::Base
  def cpu(_interval = 0.5)
    ServerStats::CpuStats.new(
      cores: 4,
      physical_cores: 4,
      usage_percent: 22.5,
      load_average: { one_minute: 1.0, five_minutes: 0.5, fifteen_minutes: 0.2 },
      model: "Mock CPU"
    )
  end

  def memory
    ServerStats::MemoryStats.new(
      total_bytes: 8 * 1024 * 1024 * 1024,
      free_bytes: 2 * 1024 * 1024 * 1024,
      available_bytes: 4 * 1024 * 1024 * 1024
    )
  end

  def disk(path = "/")
    ServerStats::DiskStats.new(
      path: path,
      filesystem: "/dev/mock1",
      total_bytes: 50 * 1024 * 1024 * 1024,
      used_bytes: 10 * 1024 * 1024 * 1024,
      available_bytes: 40 * 1024 * 1024 * 1024
    )
  end

  def system
    ServerStats::SystemStats.new(
      os: "MockOS",
      os_family: :linux,
      os_version: "1.0",
      hostname: "mock-host",
      architecture: "x86_64",
      kernel: "5.0.0",
      uptime_seconds: 3600
    )
  end
end

class ServerStatsModuleTest
  include TestRunner

  def run
    puts "\nRunning ServerStatsModuleTest..."

    # Test with custom mock collector
    original_collector = ServerStats.collector
    mock_collector = ServerStats::Collector.new(provider: MockProvider.new)
    ServerStats.collector = mock_collector

    cpu = ServerStats.cpu
    assert_equal 4, cpu.cores
    assert_equal 22.5, cpu.usage_percent
    assert_equal "Mock CPU", cpu.model

    mem = ServerStats.memory
    assert_equal 8 * 1024 * 1024 * 1024, mem.total_bytes
    assert_equal "8.00 GB", mem.total_human
    assert_equal "4.00 GB", mem.available_human

    # Alias ram
    ram = ServerStats.ram
    assert_equal mem.total_bytes, ram.total_bytes

    disk = ServerStats.disk("/data")
    assert_equal "/data", disk.path
    assert_equal 50 * 1024 * 1024 * 1024, disk.total_bytes
    assert_equal "50.00 GB", disk.total_human

    sys = ServerStats.system
    assert_equal "MockOS", sys.os
    assert_equal "mock-host", sys.hostname

    snapshot = ServerStats.all
    assert_equal 4, snapshot.cpu.cores
    assert_equal 8 * 1024 * 1024 * 1024, snapshot.memory.total_bytes

    hash = ServerStats.to_h
    assert hash[:cpu].is_a?(Hash)
    assert hash[:memory].is_a?(Hash)
    assert hash[:disk].is_a?(Hash)
    assert hash[:system].is_a?(Hash)

    json = ServerStats.to_json
    assert json.is_a?(String)
    parsed = JSON.parse(json)
    assert_equal 4, parsed["cpu"]["cores"]

    summary = ServerStats.summary
    assert_match(/SERVER STATS REPORT/, summary)
    assert_match(/MockOS/, summary)
    assert_match(/Mock CPU/, summary)
    assert_match(/8.00 GB/, summary)

    # Restore collector
    ServerStats.collector = original_collector
  end
end
