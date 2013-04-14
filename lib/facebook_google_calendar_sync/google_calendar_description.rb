require 'date'

module FacebookGoogleCalendarSync
  module GoogleCalendarDescription
    DESCRIPTION_PREFIX = "Last known Facebook event update occurred at: "
    DESCRIPTION_MIDDLE = "\nFacebook last checked at: "
    DESCRIPTION_SUFFIX = "\nTo ensure calendar synchronises properly, please do not modify this description."

    def extract_last_modified_date description
      DateTime.strptime(description[DESCRIPTION_PREFIX.size..DESCRIPTION_PREFIX.size+25])
    end

    def create_description last_known_event_update, now
      "#{DESCRIPTION_PREFIX}#{last_known_event_update.to_s}#{DESCRIPTION_MIDDLE}#{now.to_s}#{DESCRIPTION_SUFFIX}"
    end
  end
end