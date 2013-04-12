require "facebook_google_calendar_sync/version"
require 'open-uri'
require 'ri_cal'
require 'facebook_google_calendar_sync/logging'
require 'facebook_google_calendar_sync/synchroniser'
require 'facebook_google_calendar_sync/google_calendar'
require 'facebook_google_calendar_sync/google_calendar_client'
require 'active_support/core_ext/hash/indifferent_access'

module FacebookGoogleCalendarSync    

  extend Logging  
  
  DEFAULT_CONFIG = {:google_api_config_file => Pathname.new(ENV['HOME']) + '.google-api.yaml', :google_calendar_name => "My Facebook Events"}

  def self.sync config    
    config = DEFAULT_CONFIG.merge(config).with_indifferent_access    
    configure_client config[:google_api_config_file]
    facebook_calendar = retrieve_facebook_calendar config[:facebook_calendar_url]    
    google_calendar = GoogleCalendar.find_or_create_calendar config[:google_calendar_name]
    logger.info "The last Facebook event update that was synchronised to '#{google_calendar.summary}' happend at #{google_calendar.last_modified}"
    Synchroniser.new(facebook_calendar, google_calendar).synchronise
  end

  private

  def self.configure_client google_api_config_file
    GoogleCalendarClient.configure do | conf |
      conf.google_api_config_file = google_api_config_file
    end
  end

  def self.retrieve_facebook_calendar url
    open(url) { | response | components = RiCal.parse(response) }.first
  end

end




