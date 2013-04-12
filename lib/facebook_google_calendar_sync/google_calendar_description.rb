require 'date'

module FacebookGoogleCalendarSync
  module GoogleCalendarDescription
    DESCRIPTION_PREFIX = "Last known Facebook event update occurred at: "
    DESCRIPTION_MIDDLE = "\nFacebook last checked at: "
    DESCRIPTION_SUFFIX = "\nTo ensure calendar synchronises properly, please do not modify this description."

    def extract_last_modified_date description
      DateTime.strptime(description[DESCRIPTION_PREFIX.size..58])
    end

    def create_description date_time
      "#{DESCRIPTION_PREFIX}#{date_time.to_s}#{DESCRIPTION_MIDDLE}#{DateTime.now.to_s}#{DESCRIPTION_SUFFIX}"
    end    
  end
end