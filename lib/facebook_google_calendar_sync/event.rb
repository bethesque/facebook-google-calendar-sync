require 'date'

module FacebookGoogleCalendarSync    
  module Event

     def convert_event_to_hash ical_event
        {
           'summary' => ical_event.summary,
           'start' => date_hash(ical_event.dtstart),
           'end' => date_hash(ical_event.dtend),
           'iCalUID' => ical_event.uid,
           'description' => ical_event.description,
           'location' => ical_event.location
        }
     end

     def convert_google_event_to_hash google_event
      return nil unless google_event
      {
        'summary' => google_event.summary,
        'updated' => google_event.updated,
        'i_cal_uid' => google_event.i_cal_uid
      }
     end

    def merge_events target_event, source_event
      target_event.to_hash.merge(convert_event_to_hash(source_event))
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