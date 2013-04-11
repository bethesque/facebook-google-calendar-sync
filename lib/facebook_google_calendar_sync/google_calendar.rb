require 'facebook_google_calendar_sync/event'
require 'facebook_google_calendar_sync/google_calendar_client'
require 'time_zone_hack'

module FacebookGoogleCalendarSync    

  class GoogleCalendar

    include Logging
    extend Logging
    include Event
    include GoogleCalendarClient
    extend GoogleCalendarClient

    DESCRIPTION_PREFIX = "Last synchronised with Facebook: "
    DESCRIPTION_SUFFIX = "\nTo ensure calendar synchronises properly, please do not modify this description."

    def initialize details, data
      @details = details
      @data = data      
    end

    def self.set_client client
      @@client = client
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
      DateTime.strptime(description[DESCRIPTION_PREFIX.size..58]) rescue DateTime.new(0)
    end

    def last_modified= date_time
      desc = "#{DESCRIPTION_PREFIX}#{date_time.to_s}#{DESCRIPTION_SUFFIX}"
      self.description = desc
    end

    def description
      @details.description
    end

    def description= desc      
      @details.description = desc      
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

    def save_details!      
      update_calendar id, @details
    end

    def event_updated_since_calendar_last_modified facebook_event
      facebook_event.last_modified > last_modified
    end

    def event_created_since_calendar_last_modified facebook_event
      facebook_event.created > last_modified
    end

    def synchronise_events facebook_events
      facebook_events.each do | facebook_event |
        begin          
          synchronise_event facebook_event        
        rescue StandardError => e
          logger.error e
          logger.error "Error synchronising event. Please note that if this was a new event, it will not have been added to your calendar."
          logger.error convert_event_to_hash(facebook_event)
        end
      end
      update_last_modified! facebook_events
    end

    def update_last_modified! facebook_events      
      self.last_modified = date_of_most_recent_update(facebook_events).convert_time_zone(timezone)
      self.save_details!
    end

    private

    def synchronise_event facebook_event
      google_event = find_event_by_uid facebook_event.uid      
      if google_event == nil
        handle_google_event_not_found facebook_event
      else
        handle_google_event_found facebook_event, google_event
      end
    end

    def handle_google_event_not_found facebook_event
      if event_created_since_calendar_last_modified facebook_event
        logger.info "Adding '#{facebook_event.summary}' to #{@details.summary}"
        add_event id, convert_event_to_hash(facebook_event)
      else
        logger.info "Not updating '#{facebook_event.summary}' as it has been deleted from the target calendar since #{last_modified}."
      end
    end

    def handle_google_event_found facebook_event, google_event
      if event_updated_since_calendar_last_modified facebook_event
        logger.info "Updating '#{facebook_event.summary}' in #{@details.summary}"
        update_event id, google_event.id, merge_events(google_event, facebook_event)        
      else
        logger.info "Not updating '#{facebook_event.summary}' in #{@details.summary} as #{facebook_event.last_modified.to_time} is not later than #{google_event.updated.convert_time_zone('Australia/Melbourne')}"                  
      end              
    end

    def self.find_or_create_calendar_details calendar_details      
      google_calendar_details = find_calendar_details_by_summary calendar_details['summary']
      if google_calendar_details == nil
        logger.info "Creating calendar #{calendar_details['summary']} with timezone #{calendar_details['timeZone']}"
        google_calendar_details = create_calendar calendar_details
      else
        logger.info "Found existing calendar #{calendar_details['summary']}"
      end
      google_calendar_details
    end    
  end
end