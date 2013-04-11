class Time
  #Useful but not thread safe!!!!
  def convert_time_zone(to_zone)
    original_zone = ENV["TZ"]
    utc_time = dup.gmtime
    ENV["TZ"] = to_zone
    to_zone_time = utc_time.localtime
    ENV["TZ"] = original_zone
    return to_zone_time
  end
end

class DateTime
  def convert_time_zone(to_zone)
    self.to_time.convert_time_zone(to_zone).to_datetime
  end
end