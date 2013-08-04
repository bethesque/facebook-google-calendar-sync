require 'facebook_google_calendar_sync/google_calendar_client'
require 'facebook_google_calendar_sync/google_calendar_description'

module FacebookGoogleCalendarSync

  class GoogleCalendar
    extend Logging
    extend GoogleCalendarClient
    include GoogleCalendarDescription

    attr_accessor :details

    def initialize details, events_list
      @details = details
      @events_list = events_list
    end

    def self.find_or_create_calendar calendar_name
      google_calendar_details = find_or_create_calendar_details calendar_name
      events_list = get_events_list google_calendar_details.id
      GoogleCalendar.new(google_calendar_details, events_list)
    end

    def self.find_calendar calendar_name
      google_calendar_details = find_calendar_details_by_summary calendar_name
      return nil unless google_calendar_details
      events_list = get_events_list google_calendar_details.id
      GoogleCalendar.new(google_calendar_details, events_list)
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
      @events_list.items
    end

    def timezone
      @details.timeZone
    end

    def find_event_by_uid uid
      events.find{ | event | event.i_cal_uid == uid }
    end

    private

    def self.find_or_create_calendar_details calendar_name
      google_calendar_details = find_calendar_details_by_summary calendar_name
      if google_calendar_details == nil
        timezone = find_primary_calendar_details.timeZone
        logger.info "Creating Google calendar #{calendar_name} with timezone #{timezone}"
        google_calendar_details = create_calendar 'summary' => calendar_name, 'timeZone' => timezone
      else
        logger.info "Found existing Google calendar #{calendar_name}"
      end
      google_calendar_details
    end
  end
end