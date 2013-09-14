require 'time_zone_hack'
require 'facebook_google_calendar_sync/google_calendar_client'
require 'facebook_google_calendar_sync/google_calendar_description'
require 'facebook_google_calendar_sync/event_converter'
require 'facebook_google_calendar_sync/timezone'

module FacebookGoogleCalendarSync
  class Synchroniser
    include Logging
    include GoogleCalendarDescription
    include GoogleCalendarClient
    include Timezone

    def initialize(facebook_calendar, google_calendar)
      @google_calendar = with_timezone(google_calendar, google_calendar.timezone)
      @events = facebook_calendar.events.collect{ | facebook_event | with_google_calendar_timezone(facebook_event) }
    end

    def events
      @events
    end

    def google_calendar
      @google_calendar
    end

    def synchronise
      synchronise_events
      update_last_known_event_update
    end

    def convert facebook_event
      EventConverter.new(facebook_event, google_calendar.id)
    end

    def with_google_calendar_timezone target
      with_timezone(target, google_calendar.timezone)
    end

    #TODO: Fix this method!
    def synchronise_events
      errors = []
      events.each do | facebook_event |
        converted_event = nil
        begin
          converted_event = convert(facebook_event)
          synchronise_event converted_event
        rescue StandardError => e
          logger.error e
          logger.error "Error synchronising event. #{converted_event.to_hash}" rescue nil
          errors << e
        end
      end
      raise "Errors synchronising calendar" if errors.any?
    end

    def synchronise_event facebook_event
      google_event = google_calendar.find_event_by_uid facebook_event.uid
      if google_event == nil
        handle_google_event_not_found facebook_event
      else
        handle_google_event_found facebook_event, with_google_calendar_timezone(google_event)
      end
    end

    def handle_google_event_not_found facebook_event
      if event_created_since_calendar_last_modified facebook_event
        logger.info "Adding '#{facebook_event.summary}' to #{google_calendar.summary}"
        add_new_event facebook_event
      else
        logger.info "Not updating '#{facebook_event.summary}' as it has been deleted from the target calendar since #{google_calendar.last_known_event_update}."
      end
    end

    def handle_google_event_found facebook_event, google_event
      if event_updated_since_calendar_last_modified facebook_event
        logger.info "Updating '#{facebook_event.summary}' in #{google_calendar.summary}"
        update_existing_event facebook_event, google_event
      else
        logger.info "Not updating '#{facebook_event.summary}' in #{google_calendar.summary} as #{facebook_event.last_modified} is not later than #{google_event.updated}"
      end
    end

    def add_new_event facebook_event
      add_event google_calendar.id, facebook_event.to_hash
    end

    def update_existing_event facebook_event, google_event
      update_event google_calendar.id, google_event.id, merge_events(facebook_event, google_event)
    end

    def merge_events facebook_event, google_event
      google_event.to_hash.merge(facebook_event.to_hash)
    end

    def event_updated_since_calendar_last_modified facebook_event
      facebook_event.last_modified > google_calendar.last_known_event_update
    end

    def event_created_since_calendar_last_modified facebook_event
      facebook_event.created > google_calendar.last_known_event_update
    end

    def update_last_known_event_update
      last_modified = date_of_most_recent_event_update
      if last_modified != google_calendar.last_known_event_update
        logger.info "Updating description of '#{google_calendar.summary}' to include the time of the last known update, #{last_modified}"
        details = google_calendar.details.to_hash.merge({'description' => create_description(date_of_most_recent_event_update, current_time_in_google_calendar_timezone)})
        update_calendar google_calendar.id, details
      else
        logger.info "Not updating description of '#{google_calendar.summary}' as the date of the most recent update has not changed from #{google_calendar.last_known_event_update}."
      end
    end

    def current_time_in_google_calendar_timezone
      DateTime.now.convert_time_zone(google_calendar.timezone)
    end

    #Use the date of the most recent event update as our 'line in the sand' rather than the Google calendar's updated
    #property, because of the slight differences in the clocks between Facebook and Google calendar and the fact that
    #this script takes a non-zero amount of time to run, which could lead to inconsitencies in the synchronisation logic.
    def date_of_most_recent_event_update
      events.max{ | event_a, event_b | event_a.last_modified <=> event_b.last_modified }.last_modified
    end
  end
end