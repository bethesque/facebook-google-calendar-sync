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

To run:

bundle exec facebook-google-calendar-sync -t "Australia/Melbourne" -f "http://www.facebook.com/ical/u.php?uid=12345&key=67890"


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
