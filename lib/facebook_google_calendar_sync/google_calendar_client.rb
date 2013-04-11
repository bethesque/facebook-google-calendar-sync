require 'yaml'
require 'pathname'
require 'google/api_client'

module FacebookGoogleCalendarSync    

class SyncException < StandardError
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
end
