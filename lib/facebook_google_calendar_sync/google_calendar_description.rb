module FacebookGoogleCalendarSync
  module GoogleCalendarDescription
    DESCRIPTION_PREFIX = "Last synchronised with Facebook: "
    DESCRIPTION_SUFFIX = "\nTo ensure calendar synchronises properly, please do not modify this description."

    def extract_last_modified_date description
      DateTime.strptime(description[DESCRIPTION_PREFIX.size..58])
    end

    def create_description date_time
      "#{DESCRIPTION_PREFIX}#{date_time.to_s}#{DESCRIPTION_SUFFIX}"
    end    
  end
end