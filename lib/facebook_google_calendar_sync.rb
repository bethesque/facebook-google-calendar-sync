require "facebook_google_calendar_sync/version"

require 'rubygems'
require 'google/api_client'
require 'yaml'
require 'pathname'
require 'open-uri'
require 'ri_cal'
require 'logger'
require 'active_support/core_ext/hash/indifferent_access'


module FacebookGoogleCalendarSync  

  module Logging
    require 'logger'
    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::DEBUG

    def logger
      @@logger
    end
  end

  module EventToHash

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
    include EventToHash

    def initialize details, data    
      @details = details
      @data = data
    end

    def self.set_client client
      @@client = client
    end

    def self.find_or_create_calendar_by_name calendar_name
      target_calendar_details = @@client.find_calendar_details_by_name calendar_name
      if target_calendar_details == nil
        logger.info "Creating calendar #{calendar_name}"
        target_calendar_details = @@client.create_calendar calendar_name
      else
        logger.info "Found existing calendar #{calendar_name}"
      end
      
      calendar = @@client.get_calendar target_calendar_details.id
      GoogleCalendar.new(target_calendar_details, calendar)
    end

    def self.find_calendar_by_name calendar_name
      target_calendar_details = @@client.find_calendar_details_by_name calendar_name
      return nil if target_calendar_details == nil
      calendar = @@client.get_calendar target_calendar_details.id
      GoogleCalendar.new(target_calendar_details, calendar)
    end

    def id
      @details.id
    end

    def events
      @data.items
    end

    def find_event_by_uid uid
      events.find{ | event | event.i_cal_uid == uid }
    end

    def has_matching_target_event source_event
      find_event_by_uid(source_event.uid) != nil
    end

    #returns true if the source_event was newly added, 
    #false if a matching target_event already existed and was updated
    def add_or_update_event source_event
      target_event = find_event_by_uid source_event.uid
      logger.debug "Target event #{convert_google_event_to_hash(target_event)}"
      source_event_hash = convert_event_to_hash(source_event)    
      if target_event == nil
        logger.info "Adding #{source_event.summary} to #{@details.summary}"
        @@client.add_event id, source_event_hash      
        return true
      else            
        if source_event.last_modified.to_time > target_event.updated || source_event.summary == 'Ladies Brunch'
          logger.info "Updating #{source_event.summary} in #{@details.summary}"
          @@client.update_event id, target_event.id, target_event.to_hash.merge(source_event_hash)        
        else
          logger.info "Not updating #{source_event.summary} in #{@details.summary} as #{source_event.last_modified} is not later than #{target_event.updated}"        
        end      
      end
      false
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

    def find_calendar_details_by_name calendar_name
      result = @client.execute(:api_method => @calendar_service.calendar_list.list)
      result.data.items.find { | calendar | calendar.summary == calendar_name}      
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

    def create_calendar summary, timezone = 'Australia/Melbourne'
      result = @client.execute(:api_method => @calendar_service.calendars.insert,
        :parameters => {},
        :body_object => {'summary' => summary, 'timeZone' => timezone},
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
    logger.info "Starting"
    source_calendar = open(config[:source_calendar_url]) { | response | components = RiCal.parse(response) }.first
    google_calendar_client = GoogleCalendarClient.new

    GoogleCalendar.set_client google_calendar_client
    my_events_calendar = GoogleCalendar.find_or_create_calendar_by_name config[:my_events_calendar_name]

    all_events_calendar = GoogleCalendar.find_or_create_calendar_by_name config[:all_events_calendar_name]

    source_calendar.events.each do | source_event |
      begin
        is_new_event = all_events_calendar.add_or_update_event source_event
        if is_new_event || my_events_calendar.has_matching_target_event(source_event)
          my_events_calendar.add_or_update_event source_event
        end
      rescue StandardError => e
        logger.error e
      end
    end    
  end

end


# config = YAML.load_file(Pathname.new(ENV['HOME']) + '.facebook-google-calendar-sync' + 'config.yml').with_indifferent_access
# FacebookGoogleCalendarSync.sync config




