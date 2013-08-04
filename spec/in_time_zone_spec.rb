require 'spec_helper'

describe "FacebookGoogleCalendarSync::InTimeZone" do

  it "should so something" do

    class Test
      def some_date
        DateTime.strptime("2013-04-17T04:42:01+00:00")
      end
    end

    target = Test.new
    FacebookGoogleCalendarSync::InTimeZone.InTimeZone(target, 'Australia/Melbourne', :some_date)
    target.some_date.to_s.should eq "2013-04-17T14:42:01+10:00"
  end
end