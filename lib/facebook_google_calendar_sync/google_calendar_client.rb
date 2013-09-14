require 'yaml'
require 'pathname'
require 'google/api_client'
require 'ostruct'
require 'facebook_google_calendar_sync/version'
require 'facebook_google_calendar_sync/logging'

module FacebookGoogleCalendarSync

class SyncException < StandardError
end

 module GoogleCalendarClient

    include Logging

    def self.configure
      @@config = OpenStruct.new
      yield @@config

      oauth_yaml = YAML.load_file(@@config.google_api_config_file)
      @@client = Google::APIClient.new({:application_name => "Facebook to Google Calendar Sync", :application_version => FacebookGoogleCalendarSync::VERSION})
      @@client.authorization.client_id = oauth_yaml["client_id"]
      @@client.authorization.client_secret = oauth_yaml["client_secret"]
      @@client.authorization.scope = oauth_yaml["scope"]
      @@client.authorization.refresh_token = oauth_yaml["refresh_token"]
      @@client.authorization.access_token = oauth_yaml["access_token"]

      if @@client.authorization.refresh_token && @@client.authorization.expired?
        @@client.authorization.fetch_access_token!
      end

      @@calendar_service = @@client.discovered_api('calendar', 'v3')
    end

    def get_calendar_metadata calendar_id
      make_call :api_method => calendar_service.calendars.get, :parameters => {'calendarId' => calendar_id}
    end

    def find_calendar_details_by_summary calendar_summary
      get_calendar_list.items.find { | calendar | calendar.summary == calendar_summary && calendar.accessRole == 'owner'}
    end

    def find_primary_calendar_details
      get_calendar_list.items.find { | calendar | calendar.primary }
    end

    def get_calendar_list
      make_call :api_method => calendar_service.calendar_list.list
    end

    def get_calendar calendar_id
      make_call :api_method => calendar_service.events.list, :parameters => {'calendarId' => calendar_id}
    end

    def add_event calendar_id, event
      make_call :api_method => calendar_service.events.import,
        :parameters => {'calendarId' => calendar_id},
        :body_object => event
    end

    def update_event calendar_id, event_id, event
      make_call :api_method => calendar_service.events.update,
        :parameters => {'calendarId' => calendar_id, 'eventId' => event_id},
        :body_object => event
    end

    def create_calendar calendar_details
      make_call :api_method => calendar_service.calendars.insert,
        :parameters => {},
        :body_object => calendar_details
    end

    def update_calendar calendar_id, calendar_details
      make_call :api_method => calendar_service.calendars.update,
        :parameters => {'calendarId' => calendar_id},
        :body_object => calendar_details
    end

    private

    def make_call params
      request = params.merge(:headers => {'Content-Type' => 'application/json'})
      logger.debug("Calling Google Calendar API with request #{request}")
      result = client.execute(request)
      check_for_success result, params
      result.data
    end

    def client
      @@client
    end

    def calendar_service
      @@calendar_service
    end

    def check_for_success result, params
      raise SyncException.new(result.status.to_s + "\nResponse:" + result.body + "\nRequest: #{params}") unless result.status == 200
    end

  end
end
