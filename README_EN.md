# server_stats

[English](README_EN.md) | [Tiếng Việt](README.md)

A lightweight, **zero-dependency** Ruby gem designed to collect server statistics and resource utilization on **Ubuntu (Linux)** and **macOS**.

Supports both a **Command Line Interface (CLI)** and a **Ruby API** for direct integration into Rails, Sinatra, monitoring scripts, Sidekiq background jobs, health-check endpoints, and more.

---

## 🚀 Key Features

- **CPU Metrics**:
  - Total CPU core count (Logical cores & Physical cores).
  - CPU usage percentage (`usage_percent`).
  - CPU model / chip architecture (Apple Silicon, Intel, AMD).
  - System load averages (1m, 5m, 15m).
- **Memory (RAM) Metrics**:
  - Total RAM (`total_bytes` & `total_human`).
  - Actual free RAM (`free_bytes` & `free_human`).
  - Available RAM (`available_bytes` & `available_human`).
  - Used RAM (`used_bytes` & `used_human`).
  - RAM usage percentage (`usage_percent`).
  - Deep breakdown: Buffers, Cached, Swap (Linux) / Wired, Active, Inactive, Compressed (macOS).
- **Disk Storage Metrics**:
  - Total disk space (`total_bytes` & `total_human`).
  - Available / Free disk space (`available_bytes` & `available_human`).
  - Used disk space (`used_bytes` & `used_human`).
  - Disk usage percentage (`usage_percent`).
  - Filesystem & mount path (inspect any custom mount point, defaults to `/`).
- **Operating System & Hardware Info**:
  - OS name and release version (Ubuntu 20.04/22.04/24.04, macOS Sonoma/Sequoia,...).
  - Server hostname.
  - Architecture (x86_64, arm64, aarch64,...).
  - Kernel release.
  - System uptime (`uptime_seconds` & `uptime_human`).
- **Zero Dependencies**: Pure Ruby standard library implementation (`optparse`, `json`, `etc`, `socket`), requiring no native C extensions or third-party gem installations.

---

## 📋 System Requirements

- Ruby `>= 2.5.0` (fully compatible with Ruby 2.6, 2.7, 3.0, 3.1, 3.2, 3.3, 3.4+).
- Operating Systems:
  - **Ubuntu / Debian / Linux** (x86_64, aarch64).
  - **macOS** (both Apple Silicon M1/M2/M3/M4 and Intel).

---

## 📦 Installation

### Method 1: Install directly via `gem`
```bash
gem install server_stats
```

### Method 2: Add to your application's `Gemfile`
Add the following line to your `Gemfile`:
```ruby
gem 'server_stats'
```
Then install via Bundler:
```bash
bundle install
```

### Method 3: Build from source
```bash
git clone https://github.com/ntamvl/server_stats.git
cd server_stats
gem build server_stats.gemspec
gem install server_stats-0.1.0.gem
```

---

## 🖥️ Command Line Interface (CLI) Usage

After installing, run `server_stats` (or its alias `server-stats`).

### 1. Full System Overview (Default)
```bash
server_stats
```
**Example Output:**
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

### 2. CPU Metrics Only
```bash
server_stats --cpu
```
**Example Output:**
```text
CPU Cores:        16 (Physical: 16)
CPU Model:        Apple M3 Max
CPU Usage:        14.00%
Load Average:     2.97 (1m), 3.33 (5m), 3.42 (15m)
```

### 3. Memory (RAM) Metrics Only
```bash
server_stats --memory
```
**Example Output:**
```text
RAM Total:        48.00 GB
RAM Used:         32.42 GB (67.54%)
RAM Available:    15.58 GB
RAM Free:         509.45 MB
```

Display raw bytes instead of human-readable units:
```bash
server_stats --memory --raw
```
```text
RAM Total:        51539607552 bytes
RAM Used:         34326265856 bytes (66.60%)
RAM Available:    17213341696 bytes
RAM Free:         602013696 bytes
```

### 4. Disk Storage Metrics Only
Check root partition (`/`):
```bash
server_stats --disk
```
Check a specific mount point (e.g. `/data` or `/var`):
```bash
server_stats --disk /data
```
**Example Output:**
```text
Mount Path:       /data
Filesystem:       /dev/sdb1
Disk Total:       500.00 GB
Disk Used:        120.50 GB (24.10%)
Disk Available:   379.50 GB
Disk Free:        379.50 GB
```

### 5. Operating System & System Info Only
```bash
server_stats --system
```
**Example Output:**
```text
OS:               macOS 26.7.1
Hostname:         Tams-MacBook-Pro-M3-Max.local
Architecture:     arm64
Kernel:           25.6.0
Uptime:           2h 50m 3s (10203s)
```

### 6. JSON Output (Ideal for Prometheus, Datadog, Zabbix, or CI/CD pipelines)
Output formatted JSON:
```bash
server_stats --json
```
**Example JSON Output:**
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
    "used_human": "32.16 GB",
    "details": {
      "page_size_bytes": 16384,
      "active_bytes": 16198729728,
      "inactive_bytes": 16148070400,
      "wired_bytes": 4961730560,
      "purgeable_bytes": 220037120,
      "compressed_bytes": 12622397440
    }
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

Filter specific components with JSON output:
```bash
server_stats --cpu --json
server_stats --memory --json
server_stats --disk /data --json
```

Output single-line compact JSON:
```bash
server_stats --json --compact
```

### 7. Custom CPU Sampling Interval
Sample CPU over 1.0 second for higher accuracy:
```bash
server_stats --cpu --interval 1.0
```

### 8. CLI Options Reference

| Flag | Short | Description | Default |
|---|---|---|---|
| `--all` | `-a` | Display all server statistics | Default |
| `--cpu` | `-c` | Show CPU metrics only | - |
| `--memory`, `--ram` | `-m` | Show RAM/memory metrics only | - |
| `--disk [PATH]` | `-d` | Show disk storage metrics for path | `/` |
| `--system` | `-s` | Show operating system & hardware info | - |
| `--json` | `-j` | Format output as JSON | `false` |
| `--compact` | | Format JSON as a single line (when used with `-j`) | `false` |
| `--raw` | `-r` | Show raw byte numbers instead of human-readable units | `false` |
| `--interval SEC` | `-i` | CPU sampling interval in seconds | `0.5` |
| `--version` | `-v` | Display version | - |
| `--help` | `-h` | Display help banner | - |

---

## 🛠️ Ruby Application Integration (Ruby API)

### 1. Basic Usage
```ruby
require 'server_stats'

# 1. CPU Metrics
cpu = ServerStats.cpu
puts "CPU Cores: #{cpu.cores} (Physical: #{cpu.physical_cores})"
puts "CPU Usage: #{cpu.usage_percent}%"
puts "Load (1m): #{cpu.load_average[:one_minute]}"

# 2. RAM / Memory Metrics
mem = ServerStats.memory # or ServerStats.ram
puts "RAM Total:     #{mem.total_human} (#{mem.total_bytes} bytes)"
puts "RAM Available: #{mem.available_human}"
puts "RAM Free:      #{mem.free_human}"
puts "RAM Used:      #{mem.used_human} (#{mem.usage_percent}%)"

# 3. Disk Storage Metrics
disk = ServerStats.disk('/') # or custom mount: ServerStats.disk('/mnt/data')
puts "Disk Total:     #{disk.total_human}"
puts "Disk Available: #{disk.available_human}"
puts "Disk Used:      #{disk.used_human} (#{disk.usage_percent}%)"

# 4. OS & Hardware Info
sys = ServerStats.system
puts "OS:       #{sys.os} #{sys.os_version} (#{sys.architecture})"
puts "Hostname: #{sys.hostname}"
puts "Uptime:   #{sys.uptime_human}"
```

### 2. Hash and JSON Serialization
```ruby
require 'server_stats'

# Convert entire snapshot into a Ruby Hash
stats_hash = ServerStats.to_h

# Export as a JSON string
json_data = ServerStats.to_json

# Pretty-printed JSON string
pretty_json = ServerStats.to_json(pretty: true)

# Formatted ASCII summary table
puts ServerStats.summary
```

### 3. Example: Rails Health-Check Endpoint
```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def show
    stats = ServerStats.all

    # Return HTTP 503 if RAM or Disk usage exceeds 90%
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

### 4. Example: Resource Alerting Script (Slack / Telegram / Discord)
```ruby
require 'server_stats'
require 'net/http'
require 'json'

cpu  = ServerStats.cpu(interval: 1.0)
mem  = ServerStats.memory
disk = ServerStats.disk('/')

if cpu.usage_percent > 85.0 || mem.usage_percent > 85.0
  message = <<~MSG
    ⚠️ SERVER RESOURCE ALERT: #{ServerStats.system.hostname}
    - CPU: #{cpu.usage_percent}% (#{cpu.cores} cores)
    - RAM: #{mem.used_human} / #{mem.total_human} (#{mem.usage_percent}%)
    - Disk: #{disk.used_human} / #{disk.total_human} (#{disk.usage_percent}%)
  MSG
  puts message
  # Send webhook request to Slack / Telegram / Discord here...
end
```

---

## 🔬 Technical Data Collection Mechanisms

| Component | Ubuntu / Linux | macOS |
|---|---|---|
| **RAM Total & Free** | Reads `/proc/meminfo` directly (`MemTotal`, `MemAvailable`, `MemFree`, `Buffers`, `Cached`). | `sysctl -n hw.memsize` combined with page calculation from `vm_stat` (`Pages free`, `inactive`, `speculative`, `purgeable`). |
| **CPU Cores** | `Etc.nprocessors` combined with `/proc/cpuinfo` for physical cores. | `sysctl -n hw.ncpu` and `sysctl -n hw.physicalcpu`. |
| **CPU Usage %** | Two consecutive samples from `/proc/stat` calculating `delta_idle` and `delta_total`. Zero subprocesses required. | Sampled using `iostat -c 2` (or snapshot `top`), reliable within sandbox. |
| **Disk Space** | POSIX standard: `df -P -k <path>`, parses 1024-byte blocks precisely. | POSIX standard: `df -P -k <path>`. |
| **Uptime** | Reads directly from `/proc/uptime`. | Computed from boot timestamp via `sysctl -n kern.boottime`. |
| **OS Info** | Parsed from standard `/etc/os-release`. | Gathered via `sw_vers` and `uname`. |

---

## 🧪 Running Tests

The test suite is completely standalone and requires no external testing gems:

```bash
# Run test suite directly
ruby test/run_all.rb
```

Or via Rake:
```bash
rake test
```

---

## 📄 License

Distributed under the [MIT License](LICENSE).
