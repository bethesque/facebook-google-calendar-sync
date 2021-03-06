# FacebookGoogleCalendarSync

Sync Facebook Events Calendar to Google Calendar.

For Facebook and Google Calendar users

Who want to be super organised and not miss out on events or double book themselves

FacebookGoogleCalendarSync

Is a gem

That imports Facebook events into Google Calendar.

Unlike the existing "import the iCal URL provided by Facebook" solution

This gem allows the user to delete events that they are not interested in without going to Facebook to click "Not Going",

While also allowing synchronisation to be reliably and regularly scheduled* using cron or similar.

It also displays the details of the "private" Facebook events which would otherwise be hidden by Google Calendar.

*Google Calendar updates external calendars at unpredictable times, far too rarely (often more than 24 hours between updates) and doesn't allow manual refreshes. It also doesn't notify you when it has been unable to update your calendar, so you don't know when you're looking at an out of date version.

## Installation

    $ gem install facebook-google-calendar-sync

Create a Goggle permissions file to allow the gem to access your Google Calendar. This command will open a browser window. (Have found this did not work in jruby, tested succesfully in MRI ruby-1.9.3-p392)

    $ bundle exec google-api oauth-2-login --scope=https://www.googleapis.com/auth/calendar --client-id=436161995365.apps.googleusercontent.com --client-secret=WgTEjg-b8rXCRL28hweLcSuV

You will now have a .google-api.yaml file in your home directory. Note: the gem can only access your calendar data if it has this file. The synchronisation process will run locally on your computer - no external service will have access to your Google Calendar.

For more information on the last step see https://developers.google.com/google-apps/calendar/firstapp#register and the Ruby tab on https://developers.google.com/google-apps/calendar/instantiate

## Usage

You can find your Facebook iCal URL by going to your Events page, and clicking the cog icon and selecting Export. Copy the URL from the "upcoming events" link, and change the "webcal://" prefix to "http://".

To run:

    $ bundle exec facebook-google-calendar-sync -f "http://www.facebook.com/ical/u.php?uid=12345&key=67890"

If your Google API YAML file isn't stored at ~/.google-api.yaml, you can specify the location using the command line option "-c"

By default, your events will be synchronised to a calendar called "My Facebook Events". If this does not exist, it will be created using the timezone of your primary calendar. You can specify the name of the calendar (which may be a pre-existing one) using the command line option "-n"

## Long term usage

You will probably want to set this up as a cron job or similar. See the examples directory for more information.

## Known issues

When a Facebook event does not have a location, the time in the iCal export will be up to 2 days ahead of the actual date displayed in Facebook. This behaviour can also be observed in the Android mobile client. This may be because the timezone is incorrectly set when there is no location.

If a Facebook event has synchronised to your Google calendar then deleted, if the synchronisation process attempts (incorrectly) to add it again, Google Calendar will throw an exception saying that an event with this identifier already exists.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO

* Tests....
* Work out if there is a way to fix the event date when there is no location.
