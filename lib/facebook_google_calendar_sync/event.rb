require 'date'

module FacebookGoogleCalendarSync
  module Event

    def convert_event_to_hash ical_event
      {
         'summary' => "#{ical_event.summary}\n\nOrganiser: ",
         'start' => date_hash(ical_event.dtstart),
         'end' => date_hash(ical_event.dtend),
         'iCalUID' => ical_event.uid,
         'description' => ical_event.description,
         'location' => ical_event.location,
         'organizer' => organiser(ical_event)
      }
    end

    def merge_events google_event, facebook_event
      google_event.to_hash.merge(convert_event_to_hash(facebook_event))
    end

    def organiser ical_event
      matches = ical_event.organizer_property.to_s.scan(/CN=(.*):MAILTO:(.*)/).flatten
      {
        'displayName'=> matches[0],
        'email' => matches[1]
      }
    end

    def date_of_most_recent_update facebook_events
      most_recently_modified_event = facebook_events.max{ | event_a, event_b | event_a.last_modified <=> event_b.last_modified }
      most_recently_modified_event.last_modified
    end

    private

    def date_hash date_time
      if date_time.instance_of? Date
        {'date' => date_time.strftime('%Y-%m-%d')}
      else
        {'dateTime' => date_time.strftime('%Y-%m-%dT%H:%M:%S.000%:z')}
      end
    end
  end
end