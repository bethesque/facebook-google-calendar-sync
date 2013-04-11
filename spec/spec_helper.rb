require 'vcr'
require 'pathname'

lib_dir = File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift(lib_dir)

require 'facebook_google_calendar_sync'
require 'facebook_google_calendar_sync/cli'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :fakeweb
  c.configure_rspec_metadata!
end

#For VCR
RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end
