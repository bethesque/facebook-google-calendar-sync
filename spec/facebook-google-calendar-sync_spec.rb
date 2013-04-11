require 'spec_helper'

describe "FacebookGoogleCalendarSync::CLI" do
  describe "start" do    
    it "should run the CLI", :vcr do
      FacebookGoogleCalendarSync::CLI.start :google_calendar_name => "My Facebook Events", 
        :timezone => "Australia/Melbourne", 
        :facebook_calendar_url => 'http://www.facebook.com/ical/u.php?uid=TEST&key=TEST'
    end    
  end
end
