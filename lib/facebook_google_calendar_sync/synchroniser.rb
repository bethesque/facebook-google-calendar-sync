require 'facebook_google_calendar_sync/event'
require 'facebook_google_calendar_sync/google_calendar_client'
require 'facebook_google_calendar_sync/google_calendar_description'
require 'time_zone_hack'

module FacebookGoogleCalendarSync
  class Synchroniser
    include Event
    include Logging
    include GoogleCalendarDescription
    include GoogleCalendarClient

    def initialize(facebook_calendar, google_calendar)
      @facebook_calendar = facebook_calendar
      @google_calendar = google_calendar
    end

    def facebook_calendar
      @facebook_calendar
    end

    def google_calendar
      @google_calendar
    end

    def synchronise
      synchronise_events
      update_last_modified
    end

    def synchronise_events
      facebook_calendar.events.each do | facebook_event |
        begin          
          synchronise_event facebook_event        
        rescue StandardError => e
          logger.error e
          logger.error "Error synchronising event. Please note that if this was a new event, it will not have been added to your calendar."
          logger.error convert_event_to_hash(facebook_event)
        end
      end
    end

    def synchronise_event facebook_event
      google_event = google_calendar.find_event_by_uid facebook_event.uid
      if google_event == nil
        handle_google_event_not_found facebook_event
      else
        handle_google_event_found facebook_event, google_event
      end
    end  

    def handle_google_event_not_found facebook_event
      if event_created_since_calendar_last_modified facebook_event
        logger.info "Adding '#{facebook_event.summary}' to #{google_calendar.summary}"
        add_event google_calendar.id, convert_event_to_hash(facebook_event)
      else
        logger.info "Not updating '#{facebook_event.summary}' as it has been deleted from the target calendar since #{google_calendar.last_modified}."
      end
    end

    def handle_google_event_found facebook_event, google_event
      if event_updated_since_calendar_last_modified facebook_event
        logger.info "Updating '#{facebook_event.summary}' in #{google_calendar.summary}"
        update_event google_calendar.id, google_event.id, merge_events(google_event, facebook_event)        
      else
        logger.info "Not updating '#{facebook_event.summary}' in #{google_calendar.summary} as #{facebook_event.last_modified.to_time} is not later than #{google_event.updated.convert_time_zone('Australia/Melbourne')}"                  
      end              
    end

    def event_updated_since_calendar_last_modified facebook_event
      facebook_event.last_modified > google_calendar.last_modified
    end

    def event_created_since_calendar_last_modified facebook_event
      facebook_event.created > google_calendar.last_modified
    end

    def date_of_most_recent_event_update
      date_of_most_recent_update(facebook_calendar.events).convert_time_zone(google_calendar.timezone)
    end

    def update_last_modified
      last_modified = date_of_most_recent_event_update
      if last_modified != google_calendar.last_modified
        logger.info "Updating description of '#{google_calendar.summary}' to include date of most recent update, #{last_modified}"
        details = google_calendar.details.to_hash.merge({'description' => create_description(date_of_most_recent_event_update)})
        update_calendar google_calendar.id, details
      else
        logger.info "Not updating description of '#{google_calendar.summary}' as the date of the most recent update has not changed from #{google_calendar.last_modified}."
      end
    end          
  end
end