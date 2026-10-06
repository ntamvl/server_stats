# frozen_string_literal: true

require_relative "test_helper"

class ModelsTest
  include TestRunner

  def run
    puts "\nRunning ModelsTest..."

    # CpuStats
    cpu = ServerStats::CpuStats.new(
      cores: 8,
      physical_cores: 4,
      usage_percent: 25.5,
      load_average: { one_minute: 1.0, five_minutes: 0.8, fifteen_minutes: 0.5 },
      model: "Intel Core i7"
    )
    assert_equal 8, cpu.cores
    assert_equal 4, cpu.physical_cores
    assert_equal 25.5, cpu.usage_percent
    assert_equal "Intel Core i7", cpu.model
    assert_equal 1.0, cpu.load_average[:one_minute]
    assert_equal 8, cpu.to_h[:cores]

    # MemoryStats
    mem = ServerStats::MemoryStats.new(
      total_bytes: 16 * 1024 * 1024 * 1024,
      free_bytes: 4 * 1024 * 1024 * 1024,
      available_bytes: 8 * 1024 * 1024 * 1024
    )
    assert_equal 16 * 1024 * 1024 * 1024, mem.total_bytes
    assert_equal 8 * 1024 * 1024 * 1024, mem.available_bytes
    assert_equal 8 * 1024 * 1024 * 1024, mem.used_bytes
    assert_equal 50.0, mem.usage_percent
    assert_equal "16.00 GB", mem.total_human
    assert_equal "8.00 GB", mem.available_human
    assert_equal "4.00 GB", mem.free_human
    assert_equal "8.00 GB", mem.used_human

    # DiskStats
    disk = ServerStats::DiskStats.new(
      path: "/var/data",
      filesystem: "/dev/sda1",
      total_bytes: 100 * 1024 * 1024 * 1024,
      used_bytes: 20 * 1024 * 1024 * 1024,
      available_bytes: 80 * 1024 * 1024 * 1024
    )
    assert_equal "/var/data", disk.path
    assert_equal "/dev/sda1", disk.filesystem
    assert_equal 20.0, disk.usage_percent
    assert_equal "100.00 GB", disk.total_human
    assert_equal "20.00 GB", disk.used_human
    assert_equal "80.00 GB", disk.available_human

    # SystemStats
    sys = ServerStats::SystemStats.new(
      os: "Ubuntu",
      os_family: :linux,
      os_version: "22.04 LTS",
      hostname: "web-prod-1",
      architecture: "x86_64",
      kernel: "5.15.0",
      uptime_seconds: 3661
    )
    assert_equal "Ubuntu", sys.os
    assert_equal :linux, sys.os_family
    assert_equal "1h 1m 1s", sys.uptime_human

    # Snapshot
    snap = ServerStats::Snapshot.new(cpu: cpu, memory: mem, disk: disk, system: sys)
    hash = snap.to_h
    assert hash.key?(:cpu)
    assert hash.key?(:memory)
    assert hash.key?(:disk)
    assert hash.key?(:system)
    assert hash.key?(:timestamp)

    json_str = snap.to_json
    parsed = JSON.parse(json_str)
    assert_equal 8, parsed["cpu"]["cores"]
    assert_equal 50.0, parsed["memory"]["usage_percent"]
  end
end
