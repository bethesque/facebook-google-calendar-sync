# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'facebook_google_calendar_sync/version'

Gem::Specification.new do |spec|
  spec.name          = "facebook-google-calendar-sync"
  spec.version       = FacebookGoogleCalendarSync::VERSION
  spec.authors       = ["Beth"]
  spec.email         = ["beth@bethesque.com"]
  spec.description   = %q{Syncs Facebook calendar to Google calendar}
  spec.summary       = %q{Syncs Facebook calendar to Google calendar}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'google-api-client', '~>0.6'
  spec.add_dependency 'ri_cal', '~>0.8'
  spec.add_dependency 'activesupport', '~>3.2'
  #spec.add_dependency 'vcr'
  #spec.add_dependency 'fakeweb'
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
