# FacebookGoogleCalendarSync

Sync Facebook Events Calendar to Google Calendar. 

For Facebook and Google Calendar users
Who want to be super organised and not miss out on events or double book themselves
FacebookGoogleCalendarSync
Is a gem
That imports Facebook events into Google Calendar.
Unlike the existing "import the iCal URL provided by Facebook" solution
This gem allows the user to delete events that they are not interested in without going to Facebook to click "Not going",
while also allowing synchronisation to be reliably and regularly scheduled and manually triggered.

It uses two calendars - one which is the calendar you will want to display and delete events from, and another "master list" which you will want to be hidden, which is used to work out if an event is not in your display calender because you 1. deleted it or 2. it is a new event that needs to be added.

TODO: work out a way using the event created date to eliminate the dependency on the master list calendar.

## Installation

Add this line to your application's Gemfile:

    gem 'facebook-google-calendar-sync'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install facebook-google-calendar-sync

## Usage

Register the project with Google according to the https://developers.google.com/google-apps/calendar/firstapp#register
Select "Google calendar" in the services.
When filling in the API Access details, this is an "Installed application" of type "Other".
Create your .google-api.yml file according to https://developers.google.com/google-apps/calendar/instantiate

Copy your Google API yaml file to ~/.google-api.yaml
Make a copy of examples/config.yml with your own calendar names and Facebook iCal URL

To run:

bundle exec facebook-google-calendar-sync

Hide the "all_events_calendar_name" calendar so you don't see duplicate events.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
