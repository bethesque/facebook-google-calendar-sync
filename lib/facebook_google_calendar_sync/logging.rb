module FacebookGoogleCalendarSync
  module Logging
    require 'logger'

    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::INFO

    def logger
      @@logger
    end
  end
end