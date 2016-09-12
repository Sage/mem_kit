require 'objspace'

module MemKit
  class Profiler

    def self.start(logger: nil, interval: 240, limit: nil)

      if logger == nil
        logger = Logger.new(STDOUT)
      end

      logger.debug("[MemKit::Profiler] - Starting Memory Profiling. Interval: #{interval} seconds | Limit: #{limit || 'N/A'}.")

      %w'INT TERM'.each do |sig|
        Signal.trap(sig) {
          stop
        }
      end

      if @is_running == true
        raise "[MemKit::Profiler] - Profiler is already running."
      end

      @is_running = true

      @thread = Thread.new do

        while @is_running == true do

          GC.start

          result = collect(limit: limit)

          logger.debug("[MemKit::Profiler}] - #{JSON.dump(result)}")

          sleep(interval)

        end

      end

      return @thread

    end

    def self.collect(limit: nil)

      total_memory_size = ObjectSpace.memsize_of_all

      result = { total_memory_usage: format_size(total_memory_size), total_allocations: ObjectSpace.each_object{}, objects: [] }

      ObjectSpace.each_object do |o|
        update_object(o, result, total_memory_size)
      end

      result[:objects].sort! { |a,b| b[:bytes] <=> a[:bytes] }

      if limit != nil
        result[:objects] = result[:objects][0, limit]
      end

      return result

    end

    def self.stop
      @is_running = false
      if @thread != nil
        Thread.kill(@thread)
      end
    end

    def self.format_size(bytes)
      value = bytes
      unit = 'Bytes'
      if bytes >= 100000
        #format as MB
        value = bytes.to_f / 1000.0 / 1000.0
        unit = 'MB'
      elsif bytes >= 500
        #format as KB
        value = bytes.to_f / 1000.0
        unit = 'KB'
      end
      return "#{value.round(2)} #{unit}"
    end

    def self.update_object(object, result, total_memory_size)
      obj = result[:objects].detect { |o| o[:klass] == object.class }
      if obj == nil
        mem_usage = ObjectSpace.memsize_of(object)
        obj = { klass: object.class, allocation_count: 1, memory_usage_size: format_size(mem_usage), memory_usage_percentage: format_percentage(mem_usage, total_memory_size), bytes: mem_usage }
        result[:objects].push(obj)
      else
        obj[:allocation_count] += 1
        obj[:bytes] += ObjectSpace.memsize_of(object)
        obj[:memory_usage_size] = format_size(obj[:bytes])
        obj[:memory_usage_percentage] = format_percentage(obj[:bytes], total_memory_size)
      end
      return obj
    end

    def format_percentage(value, total)
      return "#{(value.to_f / total.to_f * 100.0).round(2)}%"
    end

  end
end