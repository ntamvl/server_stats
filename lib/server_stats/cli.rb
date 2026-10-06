# frozen_string_literal: true

require "optparse"
require "json"
require_relative "../server_stats"

module ServerStats
  class CLI
    def self.start(args = ARGV)
      new(args).run
    end

    def initialize(args = ARGV)
      @args = args.dup
      @options = {
        mode: :all,
        format: :text,
        disk_path: "/",
        interval: 0.5,
        raw: false,
        pretty: true
      }
    end

    def parse_options
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Cách dùng: server_stats [tuỳ chọn]"
        opts.separator ""
        opts.separator "Tuỳ chọn hiển thị:"

        opts.on("-a", "--all", "Hiển thị đầy đủ thông số hệ thống (mặc định)") do
          @options[:mode] = :all
        end

        opts.on("-c", "--cpu", "Chỉ hiển thị thông số CPU") do
          @options[:mode] = :cpu
        end

        opts.on("-m", "--memory", "--ram", "Chỉ hiển thị thông số RAM") do
          @options[:mode] = :memory
        end

        opts.on("-d", "--disk [PATH]", "Chỉ hiển thị thông số ổ cứng (mặc định: /)") do |path|
          @options[:mode] = :disk
          @options[:disk_path] = path if path && !path.empty?
        end

        opts.on("-s", "--system", "Chỉ hiển thị thông tin hệ điều hành và phần cứng") do
          @options[:mode] = :system
        end

        opts.separator ""
        opts.separator "Tuỳ chọn định dạng:"

        opts.on("-j", "--json", "Xuất dữ liệu ở định dạng JSON") do
          @options[:format] = :json
        end

        opts.on("--compact", "Xuất JSON trên 1 dòng (khi dùng với -j)") do
          @options[:pretty] = false
        end

        opts.on("-r", "--raw", "Hiển thị dung lượng dạng byte thô thay vì đơn vị đọc được (GB/MB)") do
          @options[:raw] = true
        end

        opts.on("-i", "--interval SECONDS", Float, "Thời gian lấy mẫu CPU tính bằng giây (mặc định: 0.5)") do |sec|
          @options[:interval] = [sec.to_f, 0.1].max
        end

        opts.separator ""
        opts.separator "Thông tin chung:"

        opts.on("-v", "--version", "Hiển thị phiên bản gem") do
          puts "server_stats version #{ServerStats::VERSION}"
          exit 0
        end

        opts.on("-h", "--help", "Hiển thị hướng dẫn sử dụng") do
          puts opts
          exit 0
        end
      end

      opt_parser.parse!(@args)
      # If extra non-option argument given, treat as disk path if disk mode was selected
      @options[:disk_path] = @args.first if @options[:mode] == :disk && @args.first
      @options
    end

    def run
      parse_options
      execute_command
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      warn "Lỗi cú pháp: #{e.message}"
      warn "Chạy 'server_stats --help' để xem danh sách tuỳ chọn."
      exit 1
    rescue StandardError => e
      warn "Lỗi khi lấy thông số: #{e.message}"
      exit 1
    end

    def execute_command
      case @options[:format]
      when :json
        output_json
      else
        output_text
      end
    end

    private

    def output_json
      data = case @options[:mode]
             when :cpu
               ServerStats.cpu(interval: @options[:interval]).to_h
             when :memory
               ServerStats.memory.to_h
             when :disk
               ServerStats.disk(path: @options[:disk_path]).to_h
             when :system
               ServerStats.system.to_h
             else
               ServerStats.to_h(path: @options[:disk_path], interval: @options[:interval])
             end

      puts @options[:pretty] ? JSON.pretty_generate(data) : data.to_json
    end

    def output_text
      case @options[:mode]
      when :cpu
        print_cpu(ServerStats.cpu(interval: @options[:interval]))
      when :memory
        print_memory(ServerStats.memory)
      when :disk
        print_disk(ServerStats.disk(path: @options[:disk_path]))
      when :system
        print_system(ServerStats.system)
      else
        puts ServerStats.summary(path: @options[:disk_path], interval: @options[:interval])
      end
    end

    def print_cpu(cpu)
      puts "CPU Cores:        #{cpu.cores} (Physical: #{cpu.physical_cores})"
      puts "CPU Model:        #{cpu.model || 'Unknown'}" if cpu.model
      puts "CPU Usage:        #{Formatter.format_percent(cpu.usage_percent)}"
      if cpu.load_average.any?
        puts "Load Average:     #{cpu.load_average[:one_minute]} (1m), #{cpu.load_average[:five_minutes]} (5m), #{cpu.load_average[:fifteen_minutes]} (15m)"
      end
    end

    def print_memory(mem)
      if @options[:raw]
        puts "RAM Total:        #{mem.total_bytes} bytes"
        puts "RAM Used:         #{mem.used_bytes} bytes (#{Formatter.format_percent(mem.usage_percent)})"
        puts "RAM Available:    #{mem.available_bytes} bytes"
        puts "RAM Free:         #{mem.free_bytes} bytes"
      else
        puts "RAM Total:        #{mem.total_human}"
        puts "RAM Used:         #{mem.used_human} (#{Formatter.format_percent(mem.usage_percent)})"
        puts "RAM Available:    #{mem.available_human}"
        puts "RAM Free:         #{mem.free_human}"
      end
    end

    def print_disk(disk)
      puts "Mount Path:       #{disk.path}"
      puts "Filesystem:       #{disk.filesystem}"
      if @options[:raw]
        puts "Disk Total:       #{disk.total_bytes} bytes"
        puts "Disk Used:        #{disk.used_bytes} bytes (#{Formatter.format_percent(disk.usage_percent)})"
        puts "Disk Available:   #{disk.available_bytes} bytes"
        puts "Disk Free:        #{disk.free_bytes} bytes"
      else
        puts "Disk Total:       #{disk.total_human}"
        puts "Disk Used:        #{disk.used_human} (#{Formatter.format_percent(disk.usage_percent)})"
        puts "Disk Available:   #{disk.available_human}"
        puts "Disk Free:        #{disk.free_human}"
      end
    end

    def print_system(sys)
      puts "OS:               #{sys.os} #{sys.os_version}"
      puts "Hostname:         #{sys.hostname}"
      puts "Architecture:     #{sys.architecture}"
      puts "Kernel:           #{sys.kernel}"
      puts "Uptime:           #{sys.uptime_human} (#{sys.uptime_seconds}s)"
    end
  end
end
