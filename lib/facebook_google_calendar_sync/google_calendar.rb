require 'facebook_google_calendar_sync/event'

module FacebookGoogleCalendarSync    

  class GoogleCalendar

    include Logging
    extend Logging
    include Event

    def initialize details, data    
      @details = details
      @data = data      
    end

    def self.set_client client
      @@client = client
    end

    def self.find_or_create_calendar calendar_details      
      target_calendar_details = find_or_create_calendar_details calendar_details
      calendar = @@client.get_calendar target_calendar_details.id
      GoogleCalendar.new(target_calendar_details, calendar)
    end

    def id
      @details.id
    end

    def summary
      @details.summary
    end

    def last_modified
      DateTime.strptime(description) rescue DateTime.new(0)
    end

    def last_modified= date_time
      self.description = date_time.to_s
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

    def find_event_by_uid uid
      events.find{ | event | event.i_cal_uid == uid }
    end

    def save_details!      
      @@client.update_calendar id, @details
    end

    def event_updated_since_calendar_last_modified source_event
      source_event.last_modified > last_modified
    end

    def event_created_since_calendar_last_modified source_event
      source_event.created > last_modified
    end

    def synchronise_events source_events
      source_events.each do | source_event |
        begin          
          synchronise_event source_event        
        rescue StandardError => e
          logger.error e
          logger.error "Error synchronising event. Please note that if this was a new event, it will not have been added to your calendar."
          logger.error convert_event_to_hash(source_event)
        end
      end
      update_last_modified! source_events
    end

    def update_last_modified! source_events
      most_recently_modified_event = source_events.max{ | event_a, event_b | event_a.last_modified <=> event_b.last_modified }
      self.last_modified = most_recently_modified_event.last_modified
      self.save_details!
    end

    def synchronise_event source_event
      target_event = find_event_by_uid source_event.uid      
      if target_event == nil
        handle_no_target_event source_event
      else
        handle_found_target_event source_event, target_event
      end
    end

    private

    def handle_no_target_event source_event
      if event_created_since_calendar_last_modified source_event
        logger.info "Adding '#{source_event.summary}' to #{@details.summary}"
        @@client.add_event id, convert_event_to_hash(source_event)
      else
        logger.info "Not updating '#{source_event.summary}' as it has been deleted from the target calendar since #{last_modified}."
      end
    end

    def handle_found_target_event source_event, target_event
      if event_updated_since_calendar_last_modified source_event
        logger.info "Updating '#{source_event.summary}' in #{@details.summary}"
        @@client.update_event id, target_event.id, merge_events(target_event, source_event)        
      else
        logger.info "Not updating '#{source_event.summary}' in #{@details.summary} as #{source_event.last_modified.to_time} is not later than #{target_event.updated.convert_time_zone('Australia/Melbourne')}"                  
      end              
    end

    def self.find_or_create_calendar_details calendar_details
      target_calendar_details = @@client.find_calendar_details_by_summary calendar_details['summary']
      if target_calendar_details == nil
        logger.info "Creating calendar #{calendar_details['summary']} with timezone #{calendar_details['timeZone']}"
        target_calendar_details = @@client.create_calendar calendar_details
      else
        logger.info "Found existing calendar #{calendar_details['summary']}"
      end
      target_calendar_details
    end    
  end
end