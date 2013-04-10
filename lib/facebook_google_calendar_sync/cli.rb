require 'yaml'
require 'pathname'
require 'active_support/core_ext/hash/indifferent_access'
require 'facebook_google_calendar_sync'

module FacebookGoogleCalendarSync
  class CLI
    def self.start
      config = YAML.load_file(Pathname.new(ENV['HOME']) + '.facebook-google-calendar-sync' + 'config.yml').with_indifferent_access
      FacebookGoogleCalendarSync.sync config      
    end
  end
end