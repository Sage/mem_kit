module MemKit
  class Cleaner

    def self.start(logger: nil, interval: 120)
      if logger == nil
        logger = Logger.new(STDOUT)
      end

      logger.debug("[MemKit::Cleaner] - Starting Cleaner. Interval: #{interval} seconds.")

      %w'INT TERM'.each do |sig|
        Signal.trap(sig) {
          stop
        }
      end

      if @is_running == true
        raise "[MemKit::Cleaner] - Profiler is already running."
      end

      @is_running = true

      @thread = Thread.new do

        while @is_running == true do

          GC.start

          sleep(interval)

        end

      end

      return @thread

    end

    def self.stop
      @is_running = false
      if @thread != nil
        Thread.kill(@thread)
      end
    end
  end
end