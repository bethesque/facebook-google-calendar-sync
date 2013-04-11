require "facebook_google_calendar_sync/version"
require 'open-uri'
require 'ri_cal'
require 'facebook_google_calendar_sync/logging'
require 'facebook_google_calendar_sync/google_calendar'
require 'facebook_google_calendar_sync/google_calendar_client'
require 'time_zone_hack'
require 'active_support/core_ext/hash/indifferent_access'

module FacebookGoogleCalendarSync    

  extend Logging
  
  DEFAULT_CONFIG = {:google_api_config_file => Pathname.new(ENV['HOME']) + '.google-api.yaml'}

  def self.sync config    
    config = DEFAULT_CONFIG.merge(config).with_indifferent_access    
    configure_client config[:google_api_config_file]
    source_calendar = retrieve_source_calendar config[:source_calendar_url]    
    my_events_calendar = GoogleCalendar.find_or_create_calendar 'summary' => config[:my_events_calendar_name], 'timeZone' => config[:timezone]
    logger.info "#{my_events_calendar.summary} last modified at #{my_events_calendar.last_modified.to_time}"
    my_events_calendar.synchronise_events source_calendar.events
  end

  private

  def self.configure_client google_api_config_file
    GoogleCalendarClient.configure do | conf |
      conf.google_api_config_file = google_api_config_file
    end
  end

  def self.retrieve_source_calendar url
    open(url) { | response | components = RiCal.parse(response) }.first
  end

end




