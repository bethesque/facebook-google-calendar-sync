require 'time_zone_hack'

module FacebookGoogleCalendarSync

  module Timezone

    def with_timezone target, timezone
      TimeZoneProxy.new(target, timezone)
    end

    class TimeZoneProxy < BasicObject
      def initialize target, timezone
        @target = target
        @timezone = timezone
      end

      def method_missing(method, *args, &block)
        result = @target.send(method, *args, &block)
        convert_timezone_if_date(result)
      end

      def convert_timezone_if_date result
        if result.respond_to?(:convert_time_zone)
          result.convert_time_zone(@timezone)
        else
          result
        end
      end
    end
  end

end