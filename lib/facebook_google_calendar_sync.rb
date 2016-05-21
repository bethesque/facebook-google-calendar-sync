require "facebook_google_calendar_sync/version"
require 'open-uri'
require 'ri_cal'
require 'facebook_google_calendar_sync/logging'
require 'facebook_google_calendar_sync/synchroniser'
require 'facebook_google_calendar_sync/google_calendar'
require 'facebook_google_calendar_sync/google_calendar_client'
require 'active_support/core_ext/hash/indifferent_access'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

module FacebookGoogleCalendarSync

  extend Logging

  DEFAULT_CONFIG = {
    :google_api_config_file => Pathname.new(ENV['HOME']) + '.google-api.yaml', 
    :google_calendar_name => "My Facebook Events",
    :log_level => :info
  }

  def self.sync config
    config = DEFAULT_CONFIG.merge(config).with_indifferent_access
    configure_client config[:google_api_config_file]
    configure_logger config[:log_level]
    facebook_calendar = retrieve_facebook_calendar config[:facebook_calendar_url]
    google_calendar = GoogleCalendar.find_or_create_calendar config[:google_calendar_name]
    logger.info "Last known Facebook event update occurred at #{google_calendar.last_known_event_update}"
    Synchroniser.new(facebook_calendar, google_calendar).synchronise
  end

  private

  def self.configure_logger log_level
    logger.level = Logger.const_get(log_level.to_s.upcase)
  end

  def self.configure_client google_api_config_file
    GoogleCalendarClient.configure do | conf |
      conf.google_api_config_file = google_api_config_file
    end
  end

  def self.retrieve_facebook_calendar url
    open(url) { | response | components = RiCal.parse(response) }.first
  end

end




