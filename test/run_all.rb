# frozen_string_literal: true

require_relative "test_formatter"
require_relative "test_models"
require_relative "test_linux_provider"
require_relative "test_macos_provider"
require_relative "test_server_stats"
require_relative "test_cli"

FormatterTest.new.run
ModelsTest.new.run
LinuxProviderTest.new.run
MacOsProviderTest.new.run
ServerStatsModuleTest.new.run
CLITest.new.run

success = TestRunner.report
exit(success ? 0 : 1)
