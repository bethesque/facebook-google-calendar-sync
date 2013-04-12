# FacebookGoogleCalendarSync

Sync Facebook Events Calendar to Google Calendar. 

For Facebook and Google Calendar users
Who want to be super organised and not miss out on events or double book themselves
FacebookGoogleCalendarSync
Is a gem
That imports Facebook events into Google Calendar.
Unlike the existing "import the iCal URL provided by Facebook" solution
This gem allows the user to delete events that they are not interested in without going to Facebook to click "Not Going",
while also allowing synchronisation to be reliably and regularly scheduled using cron or similar.
It also displays the details of the "private" Facebook events which would otherwise be hidden by Google Calendar.


## Installation

Add this line to your application's Gemfile:

    gem 'facebook-google-calendar-sync', :git => 'git@github.com:bethesque/facebook-google-calendar-sync.git'

And then execute:

    $ bundle

Or install the gem 'specific_install' and install it directly from git:

    $ gem install specific_install
    $ gem specific_install -l http://github.com/bethesque/facebook-google-calendar-sync.git

## Usage

Register the project with Google according to the https://developers.google.com/google-apps/calendar/firstapp#register
Select "Google calendar" in the services.
When filling in the API Access details, this is an "Installed application" of type "Other".
Create your .google-api.yml file according to https://developers.google.com/google-apps/calendar/instantiate

Copy your Google API yaml file to ~/.google-api.yaml

To run:

bundle exec facebook-google-calendar-sync -t "Australia/Melbourne" -f "http://www.facebook.com/ical/u.php?uid=12345&key=67890"

## Known issues

When a Facebook event does not have a location, the time in the iCal export will be up to 2 days ahead of the actual date displayed in Facebook. This behaviour can also be observed in the Android mobile client. This may be because the timezone is incorrectly set when there is no location.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO

* Include example cron scripts
* Change description to accuratedly describe date.
* Work out if there is a way to fix the event date when there is no location.
