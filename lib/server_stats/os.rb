# frozen_string_literal: true

require "rbconfig"

module ServerStats
  module OS
    module_function

    def host_os
      RbConfig::CONFIG["host_os"]
    end

    def macos?
      /darwin|mac os/i.match?(host_os)
    end

    def linux?
      /linux/i.match?(host_os)
    end

    def type
      if macos?
        :macos
      elsif linux?
        :linux
      else
        :unknown
      end
    end
  end
end
