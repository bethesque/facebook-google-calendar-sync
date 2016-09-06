module FacebookGoogleCalendarSync

  # Converts Facebook event into Google event hash
  class EventConverter

    attr_accessor :facebook_event, :google_calendar_id
    STATUS_MAPPINGS = {'NEEDS-ACTION' => 'needsAction', 'ACCEPTED' => 'accepted', 'TENTATIVE' => 'needsAction'}

    def initialize facebook_event, google_calendar_id
      @facebook_event = facebook_event
      @google_calendar_id = google_calendar_id
    end

    def to_hash
      {
         'summary' => summary,
         'start' => date_hash(dtstart),
         'end' => date_hash(dtend),
         'iCalUID' => uid,
         'description' => description,
         'location' => location,
         'organizer' => organiser,
         'attendees' => attendees,
         'transparency' => transparency
      }
    end

    def attendees
      [{"email" => google_calendar_id, 'responseStatus' => partstat}]
    end

    def description
      "#{facebook_event.description}\n\nOrganiser: #{organiser_name}"
    end

    def partstat
      STATUS_MAPPINGS[facebook_event.to_s.scan(/PARTSTAT::(.*)/).flatten.first]
    end

    def transparency
      partstat == 'accepted' ? 'opaque' : 'transparent'
    end

    def organiser_name
      matches = organizer_property.to_s.scan(/CN=(.*):MAILTO:(.*)/).flatten
      matches[0]
    end

    def organiser
      {
        'email' => 'noreply@facebook.com',
      }
    end

    def future?
      dtstart > DateTime.now
    end

    def past?
      dtstart < DateTime.now
    end

    def method_missing(method, *args, &block)
      if facebook_event.respond_to?(method)
        facebook_event.send(method, *args, &block)
      else
        super
      end
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