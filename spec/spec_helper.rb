require 'fdoc'
require 'fdoc/cli'
require 'rspec'
require 'tmpdir'
require 'pry-debugger'

Dir.glob(File.expand_path("../support/*.rb", __FILE__)).each { |f| require f }

RSpec.configure do |config|
  config.include CaptureHelper
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run_excluding skip: true
end
