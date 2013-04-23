#
# MetricSense for Ruby
#
# Copyright (C) 2012 Sadayuki Furuhashi
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
require 'forwardable'
require 'fluent-logger'

module MetricSense
  class Event
    def initialize(tag)
      @tag = tag
      @time = Time.now
      @values = {}
      @segments = {}
      @facts = {}
    end

    attr_reader :values, :segments, :facts

    def tag(v=nil)
      @tag = v if v
      @tag
    end

    def time(v=nil)
      @time = v if v
      @time
    end

    def value(map)
      @values.merge!(map)
      self
    end

    def segment(map)
      @segments.merge!(map)
      self
    end

    def fact(map)
      @facts.merge!(map)
      self
    end
  end

  class Collector
    def initialize(config)
      @config = config
      tag_prefix = @config['tag_prefix']
      @event_prefix = @config['event_prefix'] || 'metricsense.event'
      @metric_prefix = @config['metric_prefix'] || 'metricsense.metric'
      opts = {}
      opts[:host] = @config['host'] if @config['host']
      opts[:port] = @config['port'] if @config['port']
      @logger = Fluent::Logger::FluentLogger.new(tag_prefix, opts)
      #@logger = Fluent::Logger::ConsoleLogger.new(STDOUT)
    end

    attr_reader :config

    def measure(e)
      record = e.facts.merge(e.segments).merge!(e.values)
      @logger.post_with_time("#{@event_prefix}.#{e.tag}", record, e.time)

      values = {:count=>1}.merge!(e.values)
      values.each_pair {|k,v|
        tag = "#{@metric_prefix}.#{e.tag}.#{k}"
        record = e.segments.merge(:value=>v)
        @logger.post_with_time(tag, record, e.time)
      }
    end
  end

  class Context
    def initialize(collector)
      @collector = collector
      @events = {}
    end

    attr_reader :events

    def event(tag)
      @events[tag] ||= Event.new(tag)
    end

    alias [] event

    def clear!
      @events.clear
      nil
    end

    def measure!
      return nil unless @collector
      @events.keys.each {|k|
        event = @events[k]
        @collector.measure(event) if event.tag
        @events.delete(k)
      }
      nil
    end
  end

  module ClassMethods
    extend Forwardable

    def config(conf)
      @collector = Collector.new(conf)
      self
    end

    attr_reader :collector

    def measure(tag, values={})
      @collector.measure Event.new(tag).value(values) if @collector
    end

    def context
      Thread.current[MetricSense.to_s] ||= Context.new(@collector)
    end

    def_delegators 'context', :event, :[], :clear!, :measure!
    def_delegators 'event(nil)', :tag, :value, :segment, :fact, :time
    def_delegators 'event(nil)', :values, :segments, :facts
  end

  extend ClassMethods
end

