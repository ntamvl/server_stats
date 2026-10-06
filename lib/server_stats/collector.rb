# frozen_string_literal: true

require_relative "os"
require_relative "models"
require_relative "providers/base"
require_relative "providers/linux"
require_relative "providers/macos"

module ServerStats
  class Collector
    attr_accessor :provider

    def initialize(provider: nil)
      @provider = provider || default_provider
    end

    def cpu(interval: 0.5)
      @provider.cpu(interval)
    end

    def memory
      @provider.memory
    end

    alias ram memory

    def disk(path = "/")
      path = path[:path] if path.is_a?(Hash) && path.key?(:path)
      @provider.disk(path)
    end

    def system
      @provider.system
    end

    def snapshot(path: "/", interval: 0.5)
      Snapshot.new(
        cpu: cpu(interval: interval),
        memory: memory,
        disk: disk(path: path),
        system: system
      )
    end

    alias all snapshot

    private

    def default_provider
      case OS.type
      when :macos
        Providers::MacOs.new
      when :linux
        Providers::Linux.new
      else
        # Fallback to Linux-like or base provider
        File.exist?("/proc/meminfo") ? Providers::Linux.new : Providers::Base.new
      end
    end
  end
end
