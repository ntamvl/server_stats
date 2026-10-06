# frozen_string_literal: true

require "json"
require "time"
require_relative "formatter"

module ServerStats
  class CpuStats
    attr_reader :cores, :physical_cores, :usage_percent, :load_average, :model

    def initialize(cores:, usage_percent:, load_average: {}, physical_cores: nil, model: nil)
      @cores = cores
      @usage_percent = usage_percent ? usage_percent.round(2) : 0.0
      @load_average = load_average || {}
      @physical_cores = physical_cores || cores
      @model = model
    end

    def to_h
      {
        cores: @cores,
        physical_cores: @physical_cores,
        usage_percent: @usage_percent,
        load_average: @load_average,
        model: @model
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end

  class MemoryStats
    attr_reader :total_bytes, :free_bytes, :available_bytes, :used_bytes,
                :usage_percent, :details

    def initialize(total_bytes:, free_bytes:, available_bytes: nil, used_bytes: nil, details: {})
      @total_bytes = total_bytes.to_i
      @free_bytes = free_bytes.to_i
      @available_bytes = (available_bytes || free_bytes).to_i
      @used_bytes = (used_bytes || [@total_bytes - @available_bytes, 0].max).to_i
      @usage_percent = if @total_bytes.positive?
                         ((@used_bytes.to_f / @total_bytes) * 100.0).round(2)
                       else
                         0.0
                       end
      @details = details || {}
    end

    def total_human
      Formatter.bytes_to_human(@total_bytes)
    end

    def free_human
      Formatter.bytes_to_human(@free_bytes)
    end

    def available_human
      Formatter.bytes_to_human(@available_bytes)
    end

    def used_human
      Formatter.bytes_to_human(@used_bytes)
    end

    def to_h
      {
        total_bytes: @total_bytes,
        free_bytes: @free_bytes,
        available_bytes: @available_bytes,
        used_bytes: @used_bytes,
        usage_percent: @usage_percent,
        total_human: total_human,
        free_human: free_human,
        available_human: available_human,
        used_human: used_human,
        details: @details
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end

  class DiskStats
    attr_reader :path, :filesystem, :total_bytes, :used_bytes, :free_bytes,
                :available_bytes, :usage_percent

    def initialize(path:, filesystem:, total_bytes:, used_bytes:, available_bytes:, free_bytes: nil)
      @path = path
      @filesystem = filesystem
      @total_bytes = total_bytes.to_i
      @used_bytes = used_bytes.to_i
      @available_bytes = available_bytes.to_i
      @free_bytes = (free_bytes || available_bytes).to_i
      @usage_percent = if @total_bytes.positive?
                         ((@used_bytes.to_f / @total_bytes) * 100.0).round(2)
                       else
                         0.0
                       end
    end

    def total_human
      Formatter.bytes_to_human(@total_bytes)
    end

    def free_human
      Formatter.bytes_to_human(@free_bytes)
    end

    def available_human
      Formatter.bytes_to_human(@available_bytes)
    end

    def used_human
      Formatter.bytes_to_human(@used_bytes)
    end

    def to_h
      {
        path: @path,
        filesystem: @filesystem,
        total_bytes: @total_bytes,
        used_bytes: @used_bytes,
        free_bytes: @free_bytes,
        available_bytes: @available_bytes,
        usage_percent: @usage_percent,
        total_human: total_human,
        used_human: used_human,
        free_human: free_human,
        available_human: available_human
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end

  class SystemStats
    attr_reader :os, :os_family, :os_version, :hostname, :architecture,
                :kernel, :uptime_seconds

    def initialize(os:, os_family:, os_version:, hostname:, architecture:, kernel:, uptime_seconds:)
      @os = os
      @os_family = os_family
      @os_version = os_version
      @hostname = hostname
      @architecture = architecture
      @kernel = kernel
      @uptime_seconds = uptime_seconds.to_i
    end

    def uptime_human
      Formatter.seconds_to_human(@uptime_seconds)
    end

    def to_h
      {
        os: @os,
        os_family: @os_family,
        os_version: @os_version,
        hostname: @hostname,
        architecture: @architecture,
        kernel: @kernel,
        uptime_seconds: @uptime_seconds,
        uptime_human: uptime_human
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end

  class Snapshot
    attr_reader :cpu, :memory, :disk, :system, :timestamp

    def initialize(cpu:, memory:, disk:, system:, timestamp: nil)
      @cpu = cpu
      @memory = memory
      @disk = disk
      @system = system
      @timestamp = timestamp || Time.now.utc.iso8601
    end

    alias ram memory

    def to_h
      {
        timestamp: @timestamp,
        system: @system&.to_h,
        cpu: @cpu&.to_h,
        memory: @memory&.to_h,
        disk: @disk&.to_h
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
