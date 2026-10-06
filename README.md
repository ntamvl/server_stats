# server_stats

[Tiếng Việt](README.md) | [English](README_EN.md)

Thư viện Ruby gem nhẹ, **không phụ thuộc gem ngoài (zero-dependency)** để thu thập thông số tài nguyên và trạng thái server trên **Ubuntu (Linux)** và **macOS**.

Hỗ trợ cả **Giao diện dòng lệnh (CLI)** và **Ruby API** để tích hợp trực tiếp vào ứng dụng Rails, Sinatra, script giám sát, Sidekiq background jobs, health check endpoints,...

---

## 🚀 Các tính năng chính

- **CPU**:
  - Tổng số core CPU (Logical cores & Physical cores).
  - % Sử dụng CPU (`usage_percent`).
  - CPU model / kiến trúc chip.
  - Tải trung bình hệ thống (Load Average: 1m, 5m, 15m).
- **RAM / Bộ nhớ**:
  - Tổng dung lượng RAM (`total_bytes` & `total_human`).
  - Dung lượng RAM còn trống thực tế (`free_bytes` & `free_human`).
  - Dung lượng RAM khả dụng (`available_bytes` & `available_human`).
  - Dung lượng RAM đã dùng (`used_bytes` & `used_human`).
  - % Sử dụng RAM (`usage_percent`).
  - Chi tiết chuyên sâu: Buffer, Cached, Swap (Linux) / Wired, Active, Inactive, Compressed (macOS).
- **Ổ cứng (Disk)**:
  - Tổng dung lượng ổ cứng (`total_bytes` & `total_human`).
  - Dung lượng còn trống / khả dụng (`available_bytes` & `available_human`).
  - Dung lượng đã dùng (`used_bytes` & `used_human`).
  - % Sử dụng ổ cứng (`usage_percent`).
  - Filesystem và mount path (tuỳ biến kiểm tra bất kỳ đường dẫn mount nào, mặc định `/`).
- **Hệ điều hành & Hệ thống**:
  - Tên và phiên bản OS (Ubuntu 20.04/22.04/24.04, macOS Sonoma/Sequoia,...).
  - Hostname máy chủ.
  - Kiến trúc CPU (x86_64, arm64, aarch64,...).
  - Kernel release.
  - Thời gian uptime (`uptime_seconds` & `uptime_human`).
- **Zero Dependencies**: Sử dụng hoàn toàn Ruby Core & Standard Library (`optparse`, `json`, `etc`, `socket`), không cần biên dịch C extension hay cài thêm gem phụ thuộc.

---

## 📋 Yêu cầu môi trường

- Ruby `>= 2.5.0` (Tương thích tốt với Ruby 2.6, 2.7, 3.0, 3.1, 3.2, 3.3, 3.4+).
- Hệ điều hành:
  - **Ubuntu / Debian / Linux** (hỗ trợ kiến trúc x86_64, aarch64).
  - **macOS** (hỗ trợ cả Apple Silicon M1/M2/M3/M4 và Intel).

---

## 📦 Cài đặt

### Cách 1: Cài đặt trực tiếp qua `gem`
```bash
gem install server_stats
```

### Cách 2: Thêm vào `Gemfile` của dự án
Thêm dòng sau vào `Gemfile`:
```ruby
gem 'server_stats'
```
Sau đó chạy:
```bash
bundle install
```

### Cách 3: Cài đặt từ mã nguồn (Build từ source)
```bash
git clone https://github.com/chonoi/server_stats.git
cd server_stats
gem build server_stats.gemspec
gem install server_stats-0.1.0.gem
```

---

## 🖥️ Hướng dẫn sử dụng CLI (Command Line Interface)

Sau khi cài đặt, bạn có thể gọi lệnh `server_stats` (hoặc alias `server-stats`).

### 1. Xem toàn bộ thông số máy chủ (Mặc định)
```bash
server_stats
```
**Kết quả mẫu:**
```text
============================================================
                  SERVER STATS REPORT
============================================================
  OS:            macOS 26.7.1 (arm64)
  Hostname:      Tams-MacBook-Pro-M3-Max.local
  Uptime:        2h 49m 36s (Kernel: 25.6.0)
------------------------------------------------------------
  CPU Cores:     16 cores (Physical: 16)
  CPU Model:     Apple M3 Max
  CPU Usage:     13.00%
  Load Avg:      2.89 (1m), 3.35 (5m), 3.43 (15m)
------------------------------------------------------------
  RAM Total:     48.00 GB
  RAM Used:      32.08 GB (66.83%)
  RAM Available: 15.92 GB
  RAM Free:      822.83 MB
------------------------------------------------------------
  Disk Total:    926.35 GB (Mount: /)
  Disk Used:     11.78 GB (1.27%)
  Disk Available: 50.84 GB
  Filesystem:    /dev/disk3s1s1
============================================================
```

### 2. Chỉ xem thông số CPU
```bash
server_stats --cpu
```
**Kết quả mẫu:**
```text
CPU Cores:        16 (Physical: 16)
CPU Model:        Apple M3 Max
CPU Usage:        14.00%
Load Average:     2.97 (1m), 3.33 (5m), 3.42 (15m)
```

### 3. Chỉ xem thông số RAM / Bộ nhớ
```bash
server_stats --memory
```
**Kết quả mẫu:**
```text
RAM Total:        48.00 GB
RAM Used:         32.42 GB (67.54%)
RAM Available:    15.58 GB
RAM Free:         509.45 MB
```

Nếu muốn xem dạng byte thô (raw bytes):
```bash
server_stats --memory --raw
```
```text
RAM Total:        51539607552 bytes
RAM Used:         34326265856 bytes (66.60%)
RAM Available:    17213341696 bytes
RAM Free:         602013696 bytes
```

### 4. Chỉ xem thông số Ổ cứng (Disk)
Kiểm tra thư mục gốc `/`:
```bash
server_stats --disk
```
Kiểm tra phân vùng mount cụ thể (ví dụ `/data` hoặc `/var`):
```bash
server_stats --disk /data
```
**Kết quả mẫu:**
```text
Mount Path:       /data
Filesystem:       /dev/sdb1
Disk Total:       500.00 GB
Disk Used:        120.50 GB (24.10%)
Disk Available:   379.50 GB
Disk Free:        379.50 GB
```

### 5. Chỉ xem thông tin Hệ điều hành & Phần cứng
```bash
server_stats --system
```
**Kết quả mẫu:**
```text
OS:               macOS 26.7.1
Hostname:         Tams-MacBook-Pro-M3-Max.local
Architecture:     arm64
Kernel:           25.6.0
Uptime:           2h 50m 3s (10203s)
```

### 6. Xuất định dạng JSON (Dành cho script giám sát, Prometheus agent, Datadog, Zabbix,...)
Xuất toàn bộ hệ thống dưới dạng JSON có format (pretty JSON):
```bash
server_stats --json
```
**Kết quả JSON mẫu:**
```json
{
  "timestamp": "2026-10-05T18:06:48Z",
  "system": {
    "os": "macOS",
    "os_family": "macos",
    "os_version": "26.7.1",
    "hostname": "Tams-MacBook-Pro-M3-Max.local",
    "architecture": "arm64",
    "kernel": "25.6.0",
    "uptime_seconds": 10196,
    "uptime_human": "2h 49m 56s"
  },
  "cpu": {
    "cores": 16,
    "physical_cores": 16,
    "usage_percent": 14.0,
    "load_average": {
      "one_minute": 3.14,
      "five_minutes": 3.37,
      "fifteen_minutes": 3.43
    },
    "model": "Apple M3 Max"
  },
  "memory": {
    "total_bytes": 51539607552,
    "free_bytes": 638238720,
    "available_bytes": 17006346240,
    "used_bytes": 34533261312,
    "usage_percent": 67.0,
    "total_human": "48.00 GB",
    "free_human": "608.67 MB",
    "available_human": "15.84 GB",
    "used_human": "32.16 GB"
  },
  "disk": {
    "path": "/",
    "filesystem": "/dev/disk3s1s1",
    "total_bytes": 994662584320,
    "used_bytes": 12647350272,
    "free_bytes": 54586494976,
    "available_bytes": 54586494976,
    "usage_percent": 1.27,
    "total_human": "926.35 GB",
    "used_human": "11.78 GB",
    "free_human": "50.84 GB",
    "available_human": "50.84 GB"
  }
}
```

Kết hợp với lọc thành phần:
```bash
server_stats --cpu --json
server_stats --memory --json
server_stats --disk / --json
```

Xuất JSON trên 1 dòng duy nhất (compact):
```bash
server_stats --json --compact
```

### 7. Điều chỉnh khoảng thời gian lấy mẫu CPU
Lấy mẫu CPU trong 1.0 giây để độ chính xác cao hơn:
```bash
server_stats --cpu --interval 1.0
```

### 8. Bảng tổng hợp tham số dòng lệnh

| Tham số | Viết tắt | Ý nghĩa | Mặc định |
|---|---|---|---|
| `--all` | `-a` | Hiển thị tất cả thông số hệ thống | Mặc định |
| `--cpu` | `-c` | Chỉ hiển thị thông số CPU | - |
| `--memory`, `--ram` | `-m` | Chỉ hiển thị thông số RAM | - |
| `--disk [PATH]` | `-d` | Chỉ hiển thị thông số ổ cứng tại đường dẫn | `/` |
| `--system` | `-s` | Chỉ hiển thị thông tin hệ điều hành | - |
| `--json` | `-j` | Xuất định dạng JSON | `false` |
| `--compact` | | Xuất JSON không thụt dòng (khi kèm `-j`) | `false` |
| `--raw` | `-r` | Hiển thị byte thô thay vì GB/MB | `false` |
| `--interval SEC` | `-i` | Thời gian lấy mẫu CPU tính bằng giây | `0.5` |
| `--version` | `-v` | Xem phiên bản gem | - |
| `--help` | `-h` | Xem hướng dẫn trợ giúp | - |

---

## 🛠️ Hướng dẫn sử dụng trong ứng dụng Ruby (Ruby API)

### 1. Sử dụng cơ bản
```ruby
require 'server_stats'

# Lấy thông số CPU
cpu = ServerStats.cpu
puts "Số core CPU: #{cpu.cores}"
puts "% CPU sử dụng: #{cpu.usage_percent}%"
puts "Load 1m: #{cpu.load_average[:one_minute]}"

# Lấy thông số RAM
mem = ServerStats.memory # hoặc ServerStats.ram
puts "RAM Tổng: #{mem.total_human} (#{mem.total_bytes} bytes)"
puts "RAM Khả dụng: #{mem.available_human}"
puts "RAM Trống: #{mem.free_human}"
puts "RAM Đã dùng: #{mem.used_human} (#{mem.usage_percent}%)"

# Lấy thông số Ổ cứng
disk = ServerStats.disk('/')
puts "Ổ cứng Tổng: #{disk.total_human}"
puts "Ổ cứng Còn trống: #{disk.available_human}"
puts "Ổ cứng Đã dùng: #{disk.used_human} (#{disk.usage_percent}%)"

# Lấy thông tin Hệ điều hành
sys = ServerStats.system
puts "OS: #{sys.os} #{sys.os_version}"
puts "Hostname: #{sys.hostname}"
puts "Uptime: #{sys.uptime_human}"
```

### 2. Lấy dữ liệu dạng Hash hoặc JSON
```ruby
require 'server_stats'

# Chuyển đổi toàn bộ snapshot thành Hash
stats_hash = ServerStats.to_h

# Chuyển đổi thành chuỗi JSON
json_string = ServerStats.to_json

# Pretty JSON
pretty_json = ServerStats.to_json(pretty: true)

# Lấy báo cáo định dạng bảng chuỗi
puts ServerStats.summary
```

### 3. Ví dụ: Endpoint Health Check trong Rails
```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def show
    stats = ServerStats.all

    # Cảnh báo nếu RAM hoặc Disk vượt ngưỡng 90%
    status = if stats.memory.usage_percent > 90.0 || stats.disk.usage_percent > 90.0
               :service_unavailable
             else
               :ok
             end

    render json: {
      status: status == :ok ? "healthy" : "warning",
      stats: stats.to_h
    }, status: status
  end
end
```

### 4. Ví dụ: Script cảnh báo RAM/CPU gửi Telegram / Slack
```ruby
require 'server_stats'
require 'net/http'
require 'json'

cpu  = ServerStats.cpu(interval: 1.0)
mem  = ServerStats.memory
disk = ServerStats.disk('/')

if cpu.usage_percent > 85.0 || mem.usage_percent > 85.0
  message = <<~MSG
    ⚠️ CẢNH BÁO TÀI NGUYÊN MÁY CHỦ: #{ServerStats.system.hostname}
    - CPU: #{cpu.usage_percent}% (#{cpu.cores} cores)
    - RAM: #{mem.used_human} / #{mem.total_human} (#{mem.usage_percent}%)
    - Disk: #{disk.used_human} / #{disk.total_human} (#{disk.usage_percent}%)
  MSG
  puts message
  # Gửi webhook Slack/Telegram tại đây...
end
```

---

## 🔬 Cơ chế thu thập dữ liệu kỹ thuật

| Thành phần | Ubuntu / Linux | macOS |
|---|---|---|
| **RAM Total & Free** | Đọc `/proc/meminfo` trực tiếp (`MemTotal`, `MemAvailable`, `MemFree`, `Buffers`, `Cached`). | `sysctl -n hw.memsize` kết hợp phân tích các page từ `vm_stat` (`Pages free`, `inactive`, `speculative`, `purgeable`). |
| **CPU Cores** | `Etc.nprocessors` kết hợp `/proc/cpuinfo` cho physical cores. | `sysctl -n hw.ncpu` và `sysctl -n hw.physicalcpu`. |
| **CPU Usage %** | Lấy mẫu 2 lần liên tiếp từ `/proc/stat` tính vi sai `delta_idle` và `delta_total`. Không phụ thuộc lệnh ngoài. | Lấy mẫu từ `iostat -c 2` (hoặc snapshot `top`), an toàn trong sandbox. |
| **Disk Space** | Tiêu chuẩn POSIX: `df -P -k <path>`, parse blocks 1024-byte chính xác. | Tiêu chuẩn POSIX: `df -P -k <path>`. |
| **Uptime** | Đọc trực tiếp từ `/proc/uptime`. | Tính từ thời điểm boot hệ thống `sysctl -n kern.boottime`. |
| **OS Info** | Phân tích file `/etc/os-release` chuẩn Linux. | Sử dụng `sw_vers` và `uname`. |

---

## 🧪 Chạy kiểm thử (Testing)

Dự án đi kèm bộ test suite độc lập 100% không cần gem test bên ngoài:

```bash
# Chạy bộ test suite
ruby test/run_all.rb
```

Hoặc qua Rake:
```bash
rake test
```

---

## 📄 Bản quyền (License)

Mã nguồn được phân phối dưới giấy phép [MIT License](LICENSE).
