require 'spec_helper'
require 'pathname'

describe "FacebookGoogleCalendarSync::GoogleCalendarClient" do
  describe "configure" do

    it "should work", :vcr do
      FacebookGoogleCalendarSync::GoogleCalendarClient.configure do | config |
        config.google_api_config_file = Pathname.new(ENV['HOME']) + '.google-api.yaml'
      end
    end
  end

end