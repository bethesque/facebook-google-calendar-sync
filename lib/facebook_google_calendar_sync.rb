require "facebook_google_calendar_sync/version"
require 'open-uri'
require 'ri_cal'
require 'facebook_google_calendar_sync/logging'
require 'facebook_google_calendar_sync/google_calendar'
require 'facebook_google_calendar_sync/google_calendar_client'
require 'time_hack'


module FacebookGoogleCalendarSync    

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




