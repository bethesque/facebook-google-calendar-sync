require 'facebook_google_calendar_sync/google_calendar_client'
require 'facebook_google_calendar_sync/google_calendar_description'

module FacebookGoogleCalendarSync    

  class GoogleCalendar
    extend Logging    
    extend GoogleCalendarClient
    include GoogleCalendarDescription

    attr_accessor :details

    def initialize details, data
      @details = details
      @data = data      
    end

    def self.find_or_create_calendar calendar_details      
      google_calendar_details = find_or_create_calendar_details calendar_details
      calendar = get_calendar google_calendar_details.id
      GoogleCalendar.new(google_calendar_details, calendar)
    end

    def id
      @details.id
    end

    def summary
      @details.summary
    end

    def last_modified      
      extract_last_modified_date(description) rescue DateTime.new(0)
    end

    def description
      @details.description
    end

    def events
      @data.items
    end

    def timezone
      @details.timeZone
    end

    def find_event_by_uid uid
      events.find{ | event | event.i_cal_uid == uid }
    end

    private

    def self.find_or_create_calendar_details calendar_details      
      google_calendar_details = find_calendar_details_by_summary calendar_details['summary']
      if google_calendar_details == nil
        logger.info "Creating Google calendar #{calendar_details['summary']} with timezone #{calendar_details['timeZone']}"
        google_calendar_details = create_calendar calendar_details
      else
        logger.info "Found existing Google calendar #{calendar_details['summary']}"
      end
      google_calendar_details
    end    
  end
end