# frozen_string_literal: true

require_relative "lib/server_stats/version"

Gem::Specification.new do |spec|
  spec.name          = "server_stats"
  spec.version       = ServerStats::VERSION
  spec.authors       = ["Tam Nguyen"]
  spec.email         = ["tamnguyen@example.com"]

  spec.summary       = "Thu vien Ruby gem lay thong ke trang thai server cho Ubuntu va macOS"
  spec.description   = "Thư viện Ruby gem thu thập thông số tài nguyên hệ thống (CPU cores, % CPU sử dụng, RAM tổng/trống, Ổ cứng tổng/trống, OS) trên Ubuntu/Linux và macOS mà không cần gem phụ thuộc bên ngoài."
  spec.homepage      = "https://github.com/chonoi/server_stats"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob("{bin,lib}/**/*") + %w[README.md README_EN.md LICENSE server_stats.gemspec Rakefile Gemfile]
  spec.bindir        = "bin"
  spec.executables   = ["server_stats", "server-stats"]
  spec.require_paths = ["lib"]
end
