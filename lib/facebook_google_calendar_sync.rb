require "facebook_google_calendar_sync/version"

require 'rubygems'
require 'google/api_client'
require 'yaml'
require 'pathname'
require 'open-uri'
require 'ri_cal'
require 'logger'
require 'active_support/core_ext/hash/indifferent_access'
require 'date'

class Time
  #Useful but not thread safe!!!!
  def convert_time_zone(to_zone)
    original_zone = ENV["TZ"]
    utc_time = dup.gmtime
    ENV["TZ"] = to_zone
    to_zone_time = utc_time.localtime
    ENV["TZ"] = original_zone
    return to_zone_time
  end
end


module FacebookGoogleCalendarSync  

  module Logging
    require 'logger'
    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::INFO

    def logger
      @@logger
    end
  end

  module Event

     def convert_event_to_hash ical_event
        {
           'summary' => ical_event.summary,
           'start' => date_hash(ical_event.dtstart),
           'end' => date_hash(ical_event.dtend),
           'iCalUID' => ical_event.uid,
           'description' => ical_event.description,
           'location' => ical_event.location
        }
     end

     def convert_google_event_to_hash google_event
      return nil unless google_event
      {
        'summary' => google_event.summary,
        'updated' => google_event.updated,
        'i_cal_uid' => google_event.i_cal_uid
      }
     end

    def merge_events target_event, source_event
      target_event.to_hash.merge(convert_event_to_hash(source_event))
    end     

     private

     def date_hash date_time
        if date_time.instance_of? Date
          {'date' => date_time.strftime('%Y-%m-%d')}
        else
          {'dateTime' => date_time.strftime('%Y-%m-%dT%H:%M:%S.000%:z')}
        end
     end

  end   

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

  class GoogleCalendarClient

    def initialize
      oauth_yaml = YAML.load_file(Pathname.new(ENV['HOME']) + '.google-api.yaml')
      @client = Google::APIClient.new({:application_name => "Facebook to Google Calendar Sync", :application_version => "0.1.0"})
      @client.authorization.client_id = oauth_yaml["client_id"]
      @client.authorization.client_secret = oauth_yaml["client_secret"]
      @client.authorization.scope = oauth_yaml["scope"]
      @client.authorization.refresh_token = oauth_yaml["refresh_token"]
      @client.authorization.access_token = oauth_yaml["access_token"]

      if @client.authorization.refresh_token && @client.authorization.expired?
        @client.authorization.fetch_access_token!
      end

      @calendar_service = @client.discovered_api('calendar', 'v3')
    end

    def find_calendar_details_by_summary calendar_name
      result = @client.execute(:api_method => @calendar_service.calendar_list.list)
      result.data.items.find { | calendar | calendar.summary == calendar_name && calendar.accessRole == 'owner'}      
    end

    def get_calendar calendar_id
      result = @client.execute(:api_method => @calendar_service.events.list,
        :parameters => {'calendarId' => calendar_id})
      check_for_success result
      result.data
    end

    def add_event calendar_id, event
      result = @client.execute(:api_method => @calendar_service.events.insert,
        :parameters => {'calendarId' => calendar_id},
        :body_object => event,
        :headers => {'Content-Type' => 'application/json'}
      )
      check_for_success result
      result.data
    end

    def update_event calendar_id, event_id, event
      result = @client.execute(:api_method => @calendar_service.events.update,
        :parameters => {'calendarId' => calendar_id, 'eventId' => event_id},
        :body_object => event,
        :headers => {'Content-Type' => 'application/json'}
      )
      check_for_success result
      result.data
    end

    def create_calendar calendar_details
      result = @client.execute(:api_method => @calendar_service.calendars.insert,
        :parameters => {},
        :body_object => calendar_details,
        :headers => {'Content-Type' => 'application/json'}
      )
      check_for_success result
      result.data
    end

    def update_calendar calendar_id, calendar_details
      result = @client.execute(:api_method => @calendar_service.calendars.update,
        :parameters => {'calendarId' => calendar_id},
        :body_object => calendar_details,
        :headers => {'Content-Type' => 'application/json'}
      )
      check_for_success result
      result.data
    end

    private

    def check_for_success result
      raise SyncException.new(result.status.to_s + " " + result.body) unless result.status == 200
    end

  end
   

  class SyncException < StandardError
  end

  extend Logging

  def self.sync config
    source_calendar = retrieve_source_calendar config[:source_calendar_url]
    GoogleCalendar.set_client GoogleCalendarClient.new
    my_events_calendar = GoogleCalendar.find_or_create_calendar 'summary' => config[:my_events_calendar_name], 'timeZone' => config[:timezone]
    logger.info "#{my_events_calendar.summary} last modified at #{my_events_calendar.last_modified.to_time}"
    my_events_calendar.synchronise_events source_calendar.events    
  end

  private

  def self.retrieve_source_calendar url
    open(url) { | response | components = RiCal.parse(response) }.first
  end

end




