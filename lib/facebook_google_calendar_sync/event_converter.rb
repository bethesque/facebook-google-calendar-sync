module FacebookGoogleCalendarSync

  class EventConverter

    attr_accessor :facebook_event, :google_calendar_id, :timezone
    STATUS_MAPPINGS = {'NEEDS-ACTION' => 'needsAction', 'ACCEPTED' => 'accepted'}

    def initialize facebook_event, google_calendar_id, timezone
      @facebook_event = facebook_event
      @google_calendar_id = google_calendar_id
      @timezone = timezone
    end

    def uid
      facebook_event.uid
    end

    def last_modified
      facebook_event.last_modified.convert_time_zone(timezone)
    end

    def summary
      facebook_event.summary
    end

    def created
      facebook_event.created
    end

    def to_hash
      {
         'summary' => facebook_event.summary,
         'start' => date_hash(facebook_event.dtstart),
         'end' => date_hash(facebook_event.dtend),
         'iCalUID' => facebook_event.uid,
         'description' => description,
         'location' => facebook_event.location,
         'organizer' => organiser,
         'attendees' => attendees,
         'transparency' => transparency
      }
    end

    def attendees
      [{"email"=>google_calendar_id, 'responseStatus' => partstat}]
    end

    def description
      "#{facebook_event.description}\n\nOrganiser: #{organiser_name}"
    end

    def partstat
      STATUS_MAPPINGS[facebook_event.to_s.scan(/PARTSTAT::(.*)/).flatten.first()]
    end

    def transparency
      partstat == 'accepted' ? 'opaque' : 'transparent'
    end

    def organiser_name
      matches = facebook_event.organizer_property.to_s.scan(/CN=(.*):MAILTO:(.*)/).flatten
      matches[0]
    end

    def organiser
      {
        'email' => 'noreply@facebook.com',
      }
    end

    private

    def date_hash date_time
      if date_time.instance_of? Date
        {'date' => date_time.strftime('%Y-%m-%d')}
      else
        {'dateTime' => date_time.convert_time_zone(timezone).strftime('%Y-%m-%dT%H:%M:%S.000%:z')}
      end
    end
  end
end