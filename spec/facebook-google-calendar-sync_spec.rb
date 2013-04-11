require 'spec_helper'

describe "FacebookGoogleCalendarSync::CLI" do
  describe "start" do    
    it "should run the CLI", :vcr do
      FacebookGoogleCalendarSync::CLI.start
    end    
  end
end
