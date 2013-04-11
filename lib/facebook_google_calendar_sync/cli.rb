require 'facebook_google_calendar_sync'

module FacebookGoogleCalendarSync
  class CLI
    def self.start config
      FacebookGoogleCalendarSync.sync config
    end
  end
end