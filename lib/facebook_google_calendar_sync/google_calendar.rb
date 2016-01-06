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

    def self.find_or_create_calendar calendar_name
      google_calendar_details = find_or_create_calendar_details calendar_name
      calendar_with_events(google_calendar_details)
    end

    def self.find_calendar calendar_name
      google_calendar_details = find_calendar_details_by_summary calendar_name
      if google_calendar_details != nil
        calendar_with_events(google_calendar_details)
      else
        nil
      end
    end

    def id
      @details.id
    end

    def summary
      @details.summary
    end

    def last_known_event_update
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

    def find_calendar_details calendar_name
      google_calendar_details = find_calendar_details_by_summary calendar_name
      if google_calendar_details == nil
        return nil
      else
        logger.info "Found existing Google calendar #{calendar_name}"
      end
      google_calendar_details
    end

    private

    def self.calendar_with_events google_calendar_details
      events = get_future_events google_calendar_details.id
      GoogleCalendar.new(google_calendar_details, events)
    end

    def self.create_calendar_details calendar_name
      timezone = find_primary_calendar_details.timeZone
      create_calendar 'summary' => calendar_name, 'timeZone' => timezone
    end

    def self.find_or_create_calendar_details calendar_name
      google_calendar_details = find_calendar_details_by_summary calendar_name
      if google_calendar_details == nil
        logger.info "Creating Google calendar #{calendar_name} with timezone #{timezone}"
        google_calendar_details = create_calendar_details calendar_name
      else
        logger.info "Found existing Google calendar #{calendar_name}"
      end
      google_calendar_details
    end
  end
end