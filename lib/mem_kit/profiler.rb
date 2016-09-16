require 'objspace'

module MemKit
  class Profiler

    def self.is_running
      return @is_running
    end

    def self.start(logger: nil, interval: 120, limit: nil)

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

      @rvalue_size ||= GC::INTERNAL_CONSTANTS[:RVALUE_SIZE]

      total_memory_size = ObjectSpace.memsize_of_all

      result = { total_memory_usage: format_size(total_memory_size), total_allocations: ObjectSpace.each_object{}, symbol_count: Symbol.all_symbols.size, object_counts: ObjectSpace.count_objects, objects: [] }

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
        value = (bytes.to_f / 1000.0 / 1000.0).round(2)
        unit = 'MB'
      elsif bytes >= 500
        #format as KB
        value = (bytes.to_f / 1000.0).round(2)
        unit = 'KB'
      end
      return "#{value} #{unit}"
    end

    def self.update_object(object, result, total_memory_size)
      obj = result[:objects].detect { |o| o[:klass] == object.class }
      if obj == nil
        mem_usage = ObjectSpace.memsize_of(object) + @rvalue_size
        # compensate for API bug
        mem_usage = @rvalue_size if mem_usage > 100_000_000_000
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

    def self.format_percentage(value, total)
      return "#{(value.to_f / total.to_f * 100.0).round(2)}%"
    end

  end
end