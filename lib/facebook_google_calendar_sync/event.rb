require 'date'

module FacebookGoogleCalendarSync
  module Event

    STATUS_MAPPINGS = {'NEEDS-ACTION' => 'needsAction', 'ACCEPTED' => 'accepted'}

    def convert_event_to_hash ical_event, calendar_id
      {
         'summary' => ical_event.summary,
         'start' => date_hash(ical_event.dtstart),
         'end' => date_hash(ical_event.dtend),
         'iCalUID' => ical_event.uid,
         'description' => description(ical_event),
         'location' => ical_event.location,
         #'organizer' => organiser(ical_event),
         #'attendees' => attendees(ical_event, calendar_id),
         'transparency' => transparency(ical_event)
      }
    end

    def merge_events google_event, facebook_event, calendar_id
      google_event.to_hash.merge( convert_event_to_hash(facebook_event, calendar_id) )
    end

    def attendees ical_event, calendar_id
      [{"email"=>calendar_id, 'responseStatus' => partstat(ical_event)}]
    end

    def description facebook_event
      "#{facebook_event.description}\n\nOrganiser: #{organiser(facebook_event)['displayName']}"
    end

    def partstat ical_event
      STATUS_MAPPINGS[ical_event.to_s.scan(/PARTSTAT::(.*)/).flatten.first()]
    end

    def transparency ical_event
      partstat(ical_event) == 'accepted' ? 'opaque' : 'transparent'
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